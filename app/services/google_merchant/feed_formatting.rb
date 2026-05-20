# frozen_string_literal: true

module GoogleMerchant
  # Shared g:id and g:price formatting for all Merchant Center feeds.
  module FeedFormatting
    module_function

    def item_id(produit)
      prefix = ENV.fetch("MERCHANT_FEED_ID_PREFIX", "produit")
      "#{prefix}-#{produit.id}"
    end

    def format_price_eur(amount)
      value = amount.to_d
      format("%.2f EUR", value)
    end
  end
end
