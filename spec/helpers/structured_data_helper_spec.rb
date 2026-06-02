# frozen_string_literal: true

require "rails_helper"

RSpec.describe StructuredDataHelper, type: :helper do
  before do
    allow(helper).to receive(:request).and_return(
      instance_double(ActionDispatch::Request, base_url: "https://a1soir.com")
    )
    allow(helper).to receive(:structured_home_url).and_return("https://a1soir.com/fr/home")
    allow(helper).to receive(:structured_site_url).and_return("https://a1soir.com/fr")
    allow(helper).to receive(:structured_store_logo_url).and_return("https://a1soir.com/images/autourdunsoir_drapeau.png")
    allow(GooglePlacesService).to receive(:fetch).and_return(nil)
  end

  describe "#clothing_store_node" do
    subject(:node) { helper.send(:clothing_store_node) }

    it "uses canonical URLs without locale query params" do
      expect(node["url"]).to eq("https://a1soir.com/fr/home")
      expect(node["image"]).to eq("https://a1soir.com/images/autourdunsoir_drapeau.png")
      expect(node["url"]).not_to include("?locale=")
      expect(node["image"]).not_to include("?locale=")
    end

    it "includes address and geo coordinates" do
      expect(node["telephone"]).to eq("+33493451717")
      expect(node.dig("address", "streetAddress")).to eq("29 Boulevard Carnot")
      expect(node.dig("address", "postalCode")).to eq("06400")
      expect(node.dig("geo", "latitude")).to eq(43.5523)
    end

    it "includes area served" do
      expect(node["areaServed"]).to include(
        { "@type" => "City", "name" => "Cannes" },
        { "@type" => "City", "name" => "Nice" },
        { "@type" => "City", "name" => "Antibes" },
        { "@type" => "City", "name" => "Monaco" },
        { "@type" => "City", "name" => "Mandelieu-la-Napoule" },
        { "@type" => "City", "name" => "Grasse" }
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

    it "includes opening hours from Texte" do
      texte = Texte.create!
      texte.horaire = "Lundi: 10:00 - 18:00\nSamedi: 10:00 - 17:00"
      allow(Texte).to receive(:last).and_return(texte)

      expect(node["openingHours"]).to eq(["Lundi: 10:00 - 18:00", "Samedi: 10:00 - 17:00"])
    end

    it "falls back to default opening hours when Texte is missing" do
      allow(Texte).to receive(:last).and_return(nil)

      expect(node["openingHours"]).to eq(StoreOpeningHours::FALLBACK)
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
