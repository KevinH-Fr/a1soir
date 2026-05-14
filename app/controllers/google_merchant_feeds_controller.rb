# frozen_string_literal: true

class GoogleMerchantFeedsController < ActionController::Base
  layout false

  skip_forgery_protection

  def show
    xml = Rails.cache.fetch(
      GoogleMerchant::StaticFeed::CACHE_KEY,
      expires_in: GoogleMerchant::StaticFeed::CACHE_EXPIRES_IN
    ) do
      GoogleMerchant::StaticFeed.to_xml
    end

    render body: xml, content_type: "application/xml; charset=utf-8"
  end
end