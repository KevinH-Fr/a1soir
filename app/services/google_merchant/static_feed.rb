# frozen_string_literal: true

module GoogleMerchant
  # Builds the full Merchant Center XML served at /google_merchant_feed.xml.
  #
  # Production (Heroku): generated on each request by {GoogleMerchantFeedsController}.
  # Schedule fetches in Google Merchant Center (date/time), not via Heroku Scheduler.
  #
  # Local file: {#write!} may write `public/google_merchant_feed.xml` for debugging;
  # that path is gitignored and must not be relied on in production.
  class StaticFeed
    FEED_FILENAME = "google_merchant_feed.xml"

    class << self
      def to_xml(products: FeedBuilder.feed_scope)
        host, protocol = FeedHost.host_and_protocol
        FeedBuilder.new(
          products: products,
          channel_title: ENV.fetch("MERCHANT_FEED_CHANNEL_TITLE", "A1 Soir"),
          channel_link: FeedHost.channel_link_for(host, protocol),
          channel_description: ENV.fetch("MERCHANT_FEED_CHANNEL_DESCRIPTION", "A1 Soir — feed Google Merchant Center."),
          host: host,
          protocol: protocol
        ).to_xml
      end

      # Commerce Manager only. Same items as the Google feed, without variants
      # whose today_availability is false. Google Merchant Center must keep
      # reading to_xml (out_of_stock rows included).
      def meta_catalog_to_xml
        to_xml(products: FeedBuilder.feed_scope.where(today_availability: true))
      end

      # Writes XML to disk (development / one-off use only).
      def write!(path = Rails.root.join("public", FEED_FILENAME))
        File.write(path, to_xml, encoding: Encoding::UTF_8)
        path
      end
    end
  end
end
