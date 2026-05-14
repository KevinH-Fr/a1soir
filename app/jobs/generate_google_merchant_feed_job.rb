# frozen_string_literal: true

# Writes public/google_merchant_feed.xml via {GoogleMerchant::StaticFeed}.
#
# Local or Heroku Scheduler (same as other jobs — use +perform_now+ on the one-off dyno):
#   bin/rails runner "GenerateGoogleMerchantFeedJob.perform_now"
#
# Avoid +perform_later+ here until a dedicated queue worker and adapter are configured.
class GenerateGoogleMerchantFeedJob < ApplicationJob
  queue_as :default

  def perform
    path = GoogleMerchant::StaticFeed.write!
    Rails.logger.info("[GenerateGoogleMerchantFeedJob] wrote #{path}")
    path
  end
end
