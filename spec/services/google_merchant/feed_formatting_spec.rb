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

  describe ".item_group_id" do
    let(:long_handle) { "harper-robe-longue-fourreau-jersey-plisse-perles-fente" }

    it "returns handle unchanged when within 50 characters" do
      produit = instance_double(Produit, id: 1, handle: "robe-flux-merchant")
      expect(described_class.item_group_id(produit)).to eq("robe-flux-merchant")
    end

    it "returns a deterministic id of at most 50 characters for long handles" do
      produit = instance_double(Produit, id: 1, handle: long_handle)
      result = described_class.item_group_id(produit)

      expect(result.length).to be <= 50
      expect(result).to match(/\A[a-zA-Z0-9_-]+\z/)
      expect(described_class.item_group_id(produit)).to eq(result)
    end

    it "returns the same item_group_id for variants sharing a handle" do
      handle = long_handle
      produit_a = instance_double(Produit, id: 10, handle: handle)
      produit_b = instance_double(Produit, id: 11, handle: handle)

      expect(described_class.item_group_id(produit_a)).to eq(described_class.item_group_id(produit_b))
    end

    it "falls back to group-{id} when handle is blank" do
      produit = instance_double(Produit, id: 99, handle: nil)
      expect(described_class.item_group_id(produit)).to eq("group-99")
    end
  end

  describe ".normalize_item_group_id" do
    it "shortens handles longer than 50 characters with a stable hash suffix" do
      raw = "harper-robe-longue-fourreau-jersey-plisse-perles-fente"
      result = described_class.normalize_item_group_id(raw)

      expect(raw.length).to be > 50
      expect(result.length).to eq(50)
      expect(result).to end_with("-#{Digest::SHA256.hexdigest(raw)[0, 7]}")
    end
  end
end
