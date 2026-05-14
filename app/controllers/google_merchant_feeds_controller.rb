# frozen_string_literal: true

class GoogleMerchantFeedsController < ActionController::Base
  layout false

  skip_forgery_protection

  def show
    # raw: true avoids full Entry/Marshal wrapping; large XML is more reliable with RedisCacheStore.
    xml = Rails.cache.fetch(
      GoogleMerchant::StaticFeed::CACHE_KEY,
      expires_in: GoogleMerchant::StaticFeed::CACHE_EXPIRES_IN,
      raw: true
    ) do
      GoogleMerchant::StaticFeed.to_xml
    end

    render body: xml, content_type: "application/xml; charset=utf-8"
  end
end