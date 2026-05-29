# frozen_string_literal: true

require "digest"

module GoogleMerchant
  # Shared g:id and g:price formatting for all Merchant Center feeds.
  module FeedFormatting
    ITEM_GROUP_ID_MAX = 50
    ITEM_GROUP_ID_HASH_LENGTH = 7

    module_function

    def item_id(produit)
      prefix = ENV.fetch("MERCHANT_FEED_ID_PREFIX", "produit")
      "#{prefix}-#{produit.id}"
    end

    # Google Merchant Center: item_group_id is limited to 50 alphanumeric/dash/underscore chars.
    def item_group_id(produit)
      raw = produit.handle.presence || "group-#{produit.id}"
      normalize_item_group_id(raw)
    end

    def normalize_item_group_id(raw)
      id = raw.to_s.gsub(/[^a-zA-Z0-9_-]/, "-")
      return id if id.length <= ITEM_GROUP_ID_MAX

      suffix = Digest::SHA256.hexdigest(id)[0, ITEM_GROUP_ID_HASH_LENGTH]
      prefix_len = ITEM_GROUP_ID_MAX - 1 - suffix.length
      "#{id[0, prefix_len]}-#{suffix}"
    end

    def format_price_eur(amount)
      value = amount.to_d
      format("%.2f EUR", value)
    end
  end
end
