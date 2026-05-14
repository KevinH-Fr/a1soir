# frozen_string_literal: true

# Refreshes the Google Merchant XML in Redis ({GoogleMerchant::StaticFeed::CACHE_KEY})
# so all web dynos serve the same feed via {GoogleMerchantFeedsController}.
#
# Local or Heroku Scheduler (same as other jobs — use +perform_now+ on the one-off dyno):
#   bin/rails runner "GenerateGoogleMerchantFeedJob.perform_now"
#
# Avoid +perform_later+ here until a dedicated queue worker and adapter are configured.
class GenerateGoogleMerchantFeedJob < ApplicationJob
  queue_as :default

  def perform
    xml = GoogleMerchant::StaticFeed.to_xml
    ok = Rails.cache.write(
      GoogleMerchant::StaticFeed::CACHE_KEY,
      xml,
      expires_in: GoogleMerchant::StaticFeed::CACHE_EXPIRES_IN,
      raw: true
    )
    if ok
      Rails.logger.info(
        "[GenerateGoogleMerchantFeedJob] cached #{GoogleMerchant::StaticFeed::CACHE_KEY} (#{xml.bytesize} bytes)"
      )
    else
      Rails.logger.error(
        "[GenerateGoogleMerchantFeedJob] Rails.cache.write returned false for #{GoogleMerchant::StaticFeed::CACHE_KEY} " \
        "(#{xml.bytesize} bytes). Check Heroku logs for \"RedisCacheStore:\" (Redis timeouts / connection)."
      )
    end
    xml.bytesize
  end
end
