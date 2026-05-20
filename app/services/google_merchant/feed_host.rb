# frozen_string_literal: true

module GoogleMerchant
  # Host/protocol resolution shared by Merchant feed builders.
  module FeedHost
    module_function

    def host_and_protocol
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
