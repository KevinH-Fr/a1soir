# frozen_string_literal: true

require "rails_helper"

RSpec.describe GooglePlacesService do
  let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:payload) do
    {
      rating: 4.8,
      user_rating_count: 12,
      google_maps_uri: "https://maps.example/place",
      reviews: [ { author_name: "Camille", rating: 5, text: "Tres belle experience" } ]
    }
  end
  let(:new_payload) { payload.merge(rating: 4.9, user_rating_count: 13) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("GOOGLE_PLACES_API_KEY").and_return("test-key")
    allow(ENV).to receive(:[]).with("GOOGLE_PLACE_ID").and_return("test-place")
    allow(described_class).to receive(:cache).and_return(memory_cache)
  end

  describe ".fetch" do
    it "returns the cached payload without calling Google" do
      memory_cache.write(described_class::CACHE_KEY, payload)

      expect(described_class).not_to receive(:new)
      expect(Net::HTTP).not_to receive(:start)

      expect(described_class.fetch).to eq(payload)
    end

    it "falls back to the last successful payload once the daily cache expired" do
      memory_cache.write(described_class::STALE_KEY, payload)

      expect(Net::HTTP).not_to receive(:start)

      expect(described_class.fetch).to eq(payload)
    end

    it "returns nil without calling Google when nothing is cached" do
      expect(Net::HTTP).not_to receive(:start)

      expect(described_class.fetch).to be_nil
    end
  end

  describe ".refresh!" do
    it "replaces the cache with a successful response" do
      memory_cache.write(described_class::CACHE_KEY, payload)
      allow(described_class).to receive(:new).and_return(instance_double(described_class, call: new_payload))

      expect(described_class.refresh!).to eq(new_payload)
      expect(memory_cache.read(described_class::CACHE_KEY)).to eq(new_payload)
      expect(memory_cache.read(described_class::STALE_KEY)).to eq(new_payload)
    end

    it "keeps the previous reviews when Google fails" do
      memory_cache.write(described_class::STALE_KEY, payload)
      allow(described_class).to receive(:new).and_return(instance_double(described_class, call: nil))

      expect(described_class.refresh!).to be_nil
      expect(described_class.fetch).to eq(payload)
    end

    it "reports a failure when the cache cannot be written" do
      allow(memory_cache).to receive(:write).and_return(false)
      allow(described_class).to receive(:new).and_return(instance_double(described_class, call: new_payload))

      expect(described_class.refresh!).to be_nil
    end

    it "ignores a response without rating" do
      memory_cache.write(described_class::STALE_KEY, payload)
      allow(described_class).to receive(:new).and_return(instance_double(described_class, call: payload.merge(rating: nil)))

      expect(described_class.refresh!).to be_nil
      expect(memory_cache.read(described_class::STALE_KEY)).to eq(payload)
    end
  end

  describe "#call" do
    let(:body) do
      {
        rating: 4.7,
        userRatingCount: 98,
        googleMapsUri: "https://maps.google.com/?cid=1",
        reviews: [
          {
            rating: 5,
            text: { text: "Accueil parfait", languageCode: "fr" },
            relativePublishTimeDescription: "il y a 2 semaines",
            publishTime: "2026-10-01T10:00:00Z",
            authorAttribution: { displayName: "Lea", uri: "https://maps.google.com/u/1", photoUri: "https://lh3.example/photo" }
          }
        ]
      }.to_json
    end

    it "parses the Places API response" do
      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return(body)
      allow(Net::HTTP).to receive(:start).and_return(response)

      data = described_class.new.call

      expect(data).to include(rating: 4.7, user_rating_count: 98, google_maps_uri: "https://maps.google.com/?cid=1")
      expect(data[:reviews].first).to include(author_name: "Lea", rating: 5, text: "Accueil parfait", relative_time: "il y a 2 semaines")
    end

    it "returns nil on quota errors" do
      response = Net::HTTPTooManyRequests.new("1.1", "429", "Too Many Requests")
      allow(response).to receive(:body).and_return({ error: { message: "Quota exceeded" } }.to_json)
      allow(Net::HTTP).to receive(:start).and_return(response)

      expect(described_class.new.call).to be_nil
    end
  end
end
