# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoogleMerchant::FeedFormatting do
  let(:produit) { instance_double(Produit, id: 195) }

  describe ".item_id" do
    it "returns produit-{id} by default" do
      expect(described_class.item_id(produit)).to eq("produit-195")
    end

    it "respects MERCHANT_FEED_ID_PREFIX" do
      old = ENV["MERCHANT_FEED_ID_PREFIX"]
      ENV["MERCHANT_FEED_ID_PREFIX"] = "sku"
      expect(described_class.item_id(produit)).to eq("sku-195")
    ensure
      if old
        ENV["MERCHANT_FEED_ID_PREFIX"] = old
      else
        ENV.delete("MERCHANT_FEED_ID_PREFIX")
      end
    end
  end

  describe ".format_price_eur" do
    it "formats amounts with two decimals and EUR suffix" do
      expect(described_class.format_price_eur(695)).to eq("695.00 EUR")
      expect(described_class.format_price_eur(129.5)).to eq("129.50 EUR")
    end
  end
end
