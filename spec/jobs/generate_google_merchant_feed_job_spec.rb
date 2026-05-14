# frozen_string_literal: true

require "rails_helper"

RSpec.describe GenerateGoogleMerchantFeedJob, type: :job do
  it "delegates to GoogleMerchant::StaticFeed.write!" do
    path = Rails.root.join("public", GoogleMerchant::StaticFeed::FEED_FILENAME)
    expect(GoogleMerchant::StaticFeed).to receive(:write!).with(no_args).and_return(path)
    expect(described_class.perform_now).to eq(path)
  end
end
