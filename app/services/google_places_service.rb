class GooglePlacesService
  CACHE_KEY = "google_places_data_v3"
  STALE_KEY = "google_places_data_v3_stale"
  CACHE_TTL = 24.hours
  STALE_TTL = 7.days
  API_BASE    = "https://places.googleapis.com/v1/places"
  FIELD_MASK  = "rating,userRatingCount,reviews,googleMapsUri"
  MAX_REVIEWS = 5

  # Lecture seule : appelé par les pages publiques, ne contacte jamais Google.
  def self.fetch
    return nil unless credentials_present?

    cache.read(CACHE_KEY).presence || cache.read(STALE_KEY).presence
  end

  # Un seul appel Places API (New). En cas d'échec, les derniers avis restent en cache.
  def self.refresh!
    return nil unless credentials_present?

    result = new.call
    return nil if result.blank? || result[:rating].blank?

    stored = cache.write(CACHE_KEY, result, expires_in: CACHE_TTL) &&
             cache.write(STALE_KEY, result, expires_in: STALE_TTL)
    unless stored
      Rails.logger.error("[GooglePlacesService] Cache write failed (#{cache.class})")
      return nil
    end

    result
  end

  # NullStore et MemoryStore ne sont pas partagés entre la tâche rake et le serveur.
  def self.cache
    if Rails.cache.is_a?(ActiveSupport::Cache::NullStore) || Rails.cache.is_a?(ActiveSupport::Cache::MemoryStore)
      @file_cache ||= ActiveSupport::Cache::FileStore.new(Rails.root.join("tmp/cache/google_places"))
    else
      Rails.cache
    end
  end

  def self.credentials_present?
    ENV["GOOGLE_PLACES_API_KEY"].present? && ENV["GOOGLE_PLACE_ID"].present?
  end

  def call
    uri = URI("#{API_BASE}/#{ENV['GOOGLE_PLACE_ID']}?languageCode=fr")
    request = Net::HTTP::Get.new(uri)
    request["X-Goog-Api-Key"]   = ENV["GOOGLE_PLACES_API_KEY"]
    request["X-Goog-FieldMask"] = FIELD_MASK

    response = http_get(uri, request)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("[GooglePlacesService] Places API failed (#{response.code}: #{error_message(response)})")
      return nil
    end

    parse(JSON.parse(response.body))
  rescue StandardError => e
    Rails.logger.error("[GooglePlacesService] #{e.class}: #{e.message}")
    nil
  end

  private

  def http_get(uri, request)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 8) do |http|
      http.request(request)
    end
  end

  def error_message(response)
    JSON.parse(response.body).dig("error", "message").to_s.truncate(300)
  rescue JSON::ParserError
    response.body.to_s.truncate(300)
  end

  def parse(data)
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
