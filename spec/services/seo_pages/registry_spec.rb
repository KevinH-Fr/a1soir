# frozen_string_literal: true

require "rails_helper"

RSpec.describe SeoPages::Registry do
  describe ".find" do
    it "returns a local page" do
      page = described_class.find("robe-de-mariee-cannes", scope: "local")
      expect(page[:type]).to eq("local_landing")
      expect(page[:meta_key]).to eq("robe_de_mariee_cannes")
      expect(page.dig(:product_filters, :category_names)).to include("robes de mariée courtes")
    end

    it "returns a guide page" do
      page = described_class.find("comment-choisir-sa-robe-de-mariee", scope: "guides")
      expect(page[:type]).to eq("style_guide")
    end

    it "returns nil for unknown slug" do
      expect(described_class.find("inexistant", scope: "local")).to be_nil
    end
  end

  describe ".local_slug?" do
    it "recognizes configured local slugs" do
      expect(described_class.local_slug?("robe-de-mariee-cannes")).to be true
      expect(described_class.local_slug?("faq")).to be false
    end
  end

  describe ".sitemap_entries" do
    it "includes guide and local paths" do
      paths = described_class.sitemap_entries.map { |e| e[:path] }
      expect(paths).to include("/robe-de-mariee-cannes")
      expect(paths).to include("/guides/comment-choisir-sa-robe-de-mariee")
      expect(paths).to include("/guides/tenue-gala-ceremonie")
      expect(paths).to include("/guides/location-smoking-costume-cannes")
      expect(paths).to include("/guides/chaussures-accessoires-soiree")
    end
  end
end
