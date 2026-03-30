class GooglePlacesService
  CACHE_KEY = "google_places_data"
  CACHE_TTL = 24.hours
  API_BASE  = "https://places.googleapis.com/v1/places"
  MAX_REVIEWS = 6

  def self.fetch(referer: nil)
    return nil unless credentials_present?

    cached = Rails.cache.read(CACHE_KEY)
    return cached if cached.present?

    result = new.call(referer: referer)
    if result.present?
      Rails.cache.write(CACHE_KEY, result, expires_in: CACHE_TTL)
    end

    result
  end

  def call(referer:)
    place_id = ENV["GOOGLE_PLACE_ID"]

    uri = URI("#{API_BASE}/#{place_id}?languageCode=fr")
    request = Net::HTTP::Get.new(uri)
    request["X-Goog-Api-Key"]   = ENV["GOOGLE_PLACES_API_KEY"]
    request["X-Goog-FieldMask"] = "rating,userRatingCount,reviews,googleMapsUri"
    request["Referer"] = referer.presence || ENV["GOOGLE_PLACES_REFERRER"].presence

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      return nil
    end

    data = JSON.parse(response.body)
    parse(data)
  rescue StandardError => e
    Rails.logger.error("[GooglePlacesService] #{e.class}: #{e.message}")
    nil
  end

  private

  def self.credentials_present?
    ENV["GOOGLE_PLACES_API_KEY"].present? && ENV["GOOGLE_PLACE_ID"].present?
  end

  def parse(data)
    reviews = (data["reviews"] || []).first(MAX_REVIEWS).map do |r|
      review_text =
        if r["text"].is_a?(Hash)
          r.dig("text", "text")
        elsif r["text"].is_a?(String)
          r["text"]
        end

      {
        author_name:  r.dig("authorAttribution", "displayName"),
        author_uri:   r.dig("authorAttribution", "uri"),
        author_photo: r.dig("authorAttribution", "photoUri"),
        rating:       r["rating"],
        text:         review_text,
        relative_time: r["relativePublishTimeDescription"],
        published_at: r["publishTime"]
      }
    end

    {
      rating:            data["rating"],
      user_rating_count: data["userRatingCount"],
      google_maps_uri:   data["googleMapsUri"],
      reviews:           reviews
    }
  end
end
