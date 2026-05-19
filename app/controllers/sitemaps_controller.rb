# frozen_string_literal: true

class SitemapsController < ActionController::Base
  layout false

  skip_forgery_protection

  def show
    expires_in 1.week, public: true
    send_data Sitemap::Builder.new.to_gzip,
              type: "application/gzip",
              disposition: "inline",
              filename: "sitemap.xml.gz"
  end
end
