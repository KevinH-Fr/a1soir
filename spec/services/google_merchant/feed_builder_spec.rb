# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoogleMerchant::FeedBuilder do
  describe ".format_shipping_weight_kg" do
    it "formats whole kilograms without decimals" do
      expect(described_class.format_shipping_weight_kg(1000)).to eq("1 kg")
      expect(described_class.format_shipping_weight_kg(2000)).to eq("2 kg")
    end

    it "formats fractional kg" do
      expect(described_class.format_shipping_weight_kg(250)).to eq("0.25 kg")
      expect(described_class.format_shipping_weight_kg(500)).to eq("0.5 kg")
    end

    it "returns 0 kg for non-positive input" do
      expect(described_class.format_shipping_weight_kg(0)).to eq("0 kg")
      expect(described_class.format_shipping_weight_kg(-100)).to eq("0 kg")
    end
  end
end
