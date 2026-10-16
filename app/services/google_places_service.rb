class GooglePlacesService
  CACHE_KEY = "google_places_data_v3"
  STALE_KEY = "google_places_data_v3_stale"
  FAILURE_KEY = "google_places_data_v3_failure"
  CACHE_TTL = 24.hours
  STALE_TTL = 7.days
  FAILURE_TTL = 30.minutes
  LEGACY_BASE = "https://maps.googleapis.com/maps/api/place/details/json"
  API_BASE    = "https://places.googleapis.com/v1/places"
  MAX_REVIEWS = 5

  def self.fetch(referer: nil)
    return nil unless credentials_present?

    fresh = cache.read(CACHE_KEY)
    return fresh if fresh.present?
    return cache.read(STALE_KEY) if cache.read(FAILURE_KEY)

    # Une seule requête à la fois : le layout public appelle ce service sur chaque page.
    return cache.read(STALE_KEY) unless cache.write(FAILURE_KEY, "pending", expires_in: 30.seconds, unless_exist: true)

    result = new.call(referer: referer)
    if result.present?
      cache.write(CACHE_KEY, result, expires_in: CACHE_TTL)
      cache.write(STALE_KEY, result, expires_in: STALE_TTL)
      cache.delete(FAILURE_KEY)
      result
    else
      cache.write(FAILURE_KEY, true, expires_in: FAILURE_TTL)
      cache.read(STALE_KEY)
    end
  end

  # En développement le cache Rails est un NullStore : chaque page rappelait Google
  # et épuisait le quota partagé avec la production.
  def self.cache
    return Rails.cache unless Rails.cache.is_a?(ActiveSupport::Cache::NullStore)

    @file_cache ||= ActiveSupport::Cache::FileStore.new(Rails.root.join("tmp/cache/google_places"))
  end

  def call(referer: nil)
    fetch_legacy || fetch_v1(referer: referer)
  rescue StandardError => e
    Rails.logger.error("[GooglePlacesService] #{e.class}: #{e.message}")
    nil
  end

  private

  def self.credentials_present?
    ENV["GOOGLE_PLACES_API_KEY"].present? && ENV["GOOGLE_PLACE_ID"].present?
  end

  def fetch_legacy
    uri = URI(LEGACY_BASE)
    uri.query = URI.encode_www_form(
      place_id: ENV["GOOGLE_PLACE_ID"],
      key: ENV["GOOGLE_PLACES_API_KEY"],
      language: "fr",
      fields: "rating,user_ratings_total,reviews,url",
      reviews_sort: "newest"
    )

    response = http_get(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    unless body["status"] == "OK"
      Rails.logger.warn(
        "[GooglePlacesService] Legacy unavailable (#{body['status']}: #{body['error_message']}). Falling back to Places API v1."
      )
      return nil
    end

    parse_legacy(body["result"]).merge(reviews_sort: "newest")
  end

  def fetch_v1(referer:)
    place_id = ENV["GOOGLE_PLACE_ID"]

    uri = URI("#{API_BASE}/#{place_id}?languageCode=fr")
    request = Net::HTTP::Get.new(uri)
    request["X-Goog-Api-Key"]   = ENV["GOOGLE_PLACES_API_KEY"]
    request["X-Goog-FieldMask"] = "rating,userRatingCount,reviews,googleMapsUri"
    request["Referer"] = referer.presence || ENV["GOOGLE_PLACES_REFERRER"].presence

    response = http_get(uri, request: request)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("[GooglePlacesService] Places API v1 failed (#{response.code}: #{v1_error_message(response)})")
      return nil
    end

    parse_v1(JSON.parse(response.body)).merge(reviews_sort: "most_relevant")
  end

  def v1_error_message(response)
    body = JSON.parse(response.body)
    body.dig("error", "message").to_s.truncate(300)
  rescue JSON::ParserError
    response.body.to_s.truncate(300)
  end

  def http_get(uri, request: nil)
    request ||= Net::HTTP::Get.new(uri)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 8) do |http|
      http.request(request)
    end
  end

  def parse_legacy(result)
    reviews = build_reviews((result["reviews"] || []).first(MAX_REVIEWS)) do |r|
      published_at = Time.at(r["time"]).utc.iso8601 if r["time"].present?

      {
        author_name:   r["author_name"],
        author_uri:    r["author_url"],
        author_photo:  r["profile_photo_url"],
        rating:        r["rating"],
        text:          r["text"],
        relative_time: r["relative_time_description"],
        published_at:  published_at
      }
    end

    {
      rating:            result["rating"],
      user_rating_count: result["user_ratings_total"],
      google_maps_uri:   result["url"],
      reviews:           reviews
    }
  end

  def parse_v1(data)
    reviews = build_reviews((data["reviews"] || []).first(MAX_REVIEWS)) do |r|
      review_text =
        if r["text"].is_a?(Hash)
          r.dig("text", "text")
        elsif r["text"].is_a?(String)
          r["text"]
        end

      {
        author_name:   r.dig("authorAttribution", "displayName"),
        author_uri:    r.dig("authorAttribution", "uri"),
        author_photo:  r.dig("authorAttribution", "photoUri"),
        rating:        r["rating"],
        text:          review_text,
        relative_time: r["relativePublishTimeDescription"],
        published_at:  r["publishTime"]
      }
    end

    {
      rating:            data["rating"],
      user_rating_count: data["userRatingCount"],
      google_maps_uri:   data["googleMapsUri"],
      reviews:           reviews
    }
  end

  def build_reviews(reviews)
    reviews.filter_map do |r|
      yield(r)
    rescue StandardError => e
      Rails.logger.warn("[GooglePlacesService] Skipping review: #{e.message}")
      nil
    end
  end
end
