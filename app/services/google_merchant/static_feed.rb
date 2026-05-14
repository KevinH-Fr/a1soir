# frozen_string_literal: true

module GoogleMerchant
  # Builds the full Merchant Center XML (same output as the former dynamic endpoint).
  #
  # Production (Heroku): XML is stored in Redis under {CACHE_KEY} and served by
  # {GoogleMerchantFeedsController}. {GenerateGoogleMerchantFeedJob} refreshes the cache.
  #
  # Local file: {#write!} may still write `public/google_merchant_feed.xml` for debugging;
  # that path is gitignored and must not be relied on in production.
  class StaticFeed
    FEED_FILENAME = "google_merchant_feed.xml"
    CACHE_KEY = "google_merchant_feed_xml"
    CACHE_EXPIRES_IN = 24.hours

    class << self
      def to_xml
        host, protocol = feed_host_and_protocol
        FeedBuilder.new(
          products: FeedBuilder.feed_scope,
          channel_title: ENV.fetch("MERCHANT_FEED_CHANNEL_TITLE", "A1 Soir"),
          channel_link: channel_link_for(host, protocol),
          channel_description: ENV.fetch("MERCHANT_FEED_CHANNEL_DESCRIPTION", "A1 Soir — feed Google Merchant Center."),
          host: host,
          protocol: protocol
        ).to_xml
      end

      # Writes XML to disk (development / one-off use only). Production uses Redis cache.
      def write!(path = Rails.root.join("public", FEED_FILENAME))
        File.write(path, to_xml, encoding: Encoding::UTF_8)
        path
      end

      private

      def feed_host_and_protocol
        raw = ENV.fetch("MERCHANT_FEED_HOST") do
          ENV.fetch("SITEMAP_HOST", "http://www.example.com")
        end
        uri = URI.parse(raw.to_s)
        host = uri.host.presence || "www.example.com"
        protocol = uri.scheme.presence || "https"
        [host, protocol]
      rescue URI::InvalidURIError
        ["www.example.com", "https"]
      end

      def channel_link_for(host, protocol)
        Rails.application.routes.url_helpers.localized_root_url(
          locale: I18n.default_locale,
          host: host,
          protocol: protocol
        )
      end
    end
  end
end
