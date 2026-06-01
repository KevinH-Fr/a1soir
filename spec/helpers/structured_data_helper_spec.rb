# frozen_string_literal: true

require "rails_helper"

RSpec.describe StructuredDataHelper, type: :helper do
  before do
    allow(helper).to receive(:root_url).and_return("http://www.example.com/fr/")
    allow(GooglePlacesService).to receive(:fetch).and_return(nil)
  end

  describe "#clothing_store_node" do
    subject(:node) { helper.send(:clothing_store_node) }

    it "includes address and geo coordinates" do
      expect(node["telephone"]).to eq("+33493451717")
      expect(node.dig("address", "streetAddress")).to eq("29 Boulevard Carnot")
      expect(node.dig("address", "postalCode")).to eq("06400")
      expect(node.dig("geo", "latitude")).to eq(43.5523)
    end

    it "includes area served" do
      expect(node["areaServed"]).to include(
        { "@type" => "City", "name" => "Cannes" }
      )
    end

    context "when Google Places data is cached" do
      before do
        allow(GooglePlacesService).to receive(:fetch).and_return(
          rating: 4.8,
          user_rating_count: 120
        )
      end

      it "includes aggregate rating" do
        expect(node.dig("aggregateRating", "ratingValue")).to eq(4.8)
        expect(node.dig("aggregateRating", "reviewCount")).to eq(120)
      end
    end
  end

  describe "#faq_page_schema" do
    it "returns FAQPage with questions from locales" do
      schema = helper.faq_page_schema

      expect(schema["@type"]).to eq("FAQPage")
      expect(schema["mainEntity"]).to be_an(Array)
      expect(schema["mainEntity"].length).to be >= 20
      expect(schema["mainEntity"].first).to include(
        "@type" => "Question",
        "name" => kind_of(String),
        "acceptedAnswer" => kind_of(Hash)
      )
    end
  end
end
