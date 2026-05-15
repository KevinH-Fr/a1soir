# frozen_string_literal: true

class GoogleMerchantFeedsController < ActionController::Base
  layout false

  skip_forgery_protection

  def show
    xml = GoogleMerchant::StaticFeed.to_xml
    render body: xml, content_type: "application/xml; charset=utf-8"
  end
end
