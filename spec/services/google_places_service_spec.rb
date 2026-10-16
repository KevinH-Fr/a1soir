# frozen_string_literal: true

require "rails_helper"

RSpec.describe GooglePlacesService do
  let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:payload) do
    {
      rating: 4.8,
      user_rating_count: 12,
      google_maps_uri: "https://maps.example/place",
      reviews_sort: "most_relevant",
      reviews: [ { author_name: "Camille", rating: 5, text: "Tres belle experience" } ]
    }
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("GOOGLE_PLACES_API_KEY").and_return("test-key")
    allow(ENV).to receive(:[]).with("GOOGLE_PLACE_ID").and_return("test-place")
    allow(described_class).to receive(:cache).and_return(memory_cache)
  end

  it "returns the fresh payload without calling Google" do
    memory_cache.write(described_class::CACHE_KEY, payload)

    expect(described_class).not_to receive(:new)

    expect(described_class.fetch).to eq(payload)
  end

  it "keeps a stale copy of a successful response" do
    service = instance_double(described_class, call: payload)
    allow(described_class).to receive(:new).and_return(service)

    expect(described_class.fetch).to eq(payload)
    expect(memory_cache.read(described_class::STALE_KEY)).to eq(payload)
    expect(memory_cache.read(described_class::FAILURE_KEY)).to be_nil
  end

  it "serves the last reviews when Google fails" do
    memory_cache.write(described_class::STALE_KEY, payload)
    service = instance_double(described_class, call: nil)
    allow(described_class).to receive(:new).and_return(service)

    expect(described_class.fetch).to eq(payload)
    expect(memory_cache.read(described_class::FAILURE_KEY)).to eq(true)
  end

  it "does not call Google again during the failure window" do
    memory_cache.write(described_class::FAILURE_KEY, true)
    memory_cache.write(described_class::STALE_KEY, payload)

    expect(described_class).not_to receive(:new)

    expect(described_class.fetch).to eq(payload)
  end
end
