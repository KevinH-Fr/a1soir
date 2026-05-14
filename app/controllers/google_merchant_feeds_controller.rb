# frozen_string_literal: true

# Public product feed for Google Merchant Center (RSS 2.0 + g: namespace).
# Stays outside Public::ApplicationController for a stable XML response and explicit URL host.
class GoogleMerchantFeedsController < ActionController::Base
  def show
    host, protocol = feed_host_and_protocol
    xml = GoogleMerchant::FeedBuilder.new(
      products: GoogleMerchant::FeedBuilder.feed_scope,
      channel_title: ENV.fetch("MERCHANT_FEED_CHANNEL_TITLE", "A1 Soir"),
      channel_link: channel_link_for(host, protocol),
      channel_description: ENV.fetch("MERCHANT_FEED_CHANNEL_DESCRIPTION", "A1 Soir — feed Google Merchant Center."),
      host: host,
      protocol: protocol
    ).to_xml

    render body: xml, content_type: "application/xml; charset=utf-8"
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
