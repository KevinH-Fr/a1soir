# frozen_string_literal: true

module GoogleMerchant
  # Builds the local inventory XML served at /google_local_inventory_feed.xml.
  class LocalInventoryFeed
    FEED_FILENAME = "google_local_inventory_feed.xml"

    class << self
      def to_xml
        host, protocol = FeedHost.host_and_protocol
        LocalInventoryFeedBuilder.new(
          products: LocalInventoryFeedBuilder.feed_scope,
          channel_title: ENV.fetch("MERCHANT_LOCAL_FEED_CHANNEL_TITLE", "A1soir - Inventaire local"),
          channel_link: FeedHost.channel_link_for(host, protocol),
          channel_description: ENV.fetch(
            "MERCHANT_LOCAL_FEED_CHANNEL_DESCRIPTION",
            "Inventaire boutique A1soir Cannes"
          )
        ).to_xml
      end
    end
  end
end
