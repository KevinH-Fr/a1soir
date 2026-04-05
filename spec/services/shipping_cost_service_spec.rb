# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShippingCostService do
  describe ".fee_cents_for" do
    context "first tier (0–250g → 7€)" do
      it "returns 700 for 0g" do
        expect(described_class.fee_cents_for(0)).to eq(700)
      end

      it "returns 700 for 250g (top of tier)" do
        expect(described_class.fee_cents_for(250)).to eq(700)
      end
    end

    context "second tier (251–500g → 8€)" do
      it "returns 800 for 251g (just above first tier)" do
        expect(described_class.fee_cents_for(251)).to eq(800)
      end

      it "returns 800 for 500g (top of tier)" do
        expect(described_class.fee_cents_for(500)).to eq(800)
      end
    end

    context "third tier (501–750g → 9€)" do
      it "returns 900 for 501g" do
        expect(described_class.fee_cents_for(501)).to eq(900)
      end

      it "returns 900 for 750g" do
        expect(described_class.fee_cents_for(750)).to eq(900)
      end
    end

    context "fourth tier (751–1000g → 9€)" do
      it "returns 900 for 751g" do
        expect(described_class.fee_cents_for(751)).to eq(900)
      end

      it "returns 900 for 1000g (top of tier)" do
        expect(described_class.fee_cents_for(1000)).to eq(900)
      end
    end

    context "fifth tier (1001–2000g → 10€)" do
      it "returns 1000 for 1001g" do
        expect(described_class.fee_cents_for(1001)).to eq(1000)
      end

      it "returns 1000 for 2000g (top of tier)" do
        expect(described_class.fee_cents_for(2000)).to eq(1000)
      end
    end

    context "maximum tier (14001–15000g → 21€)" do
      it "returns 2100 for 15000g (top of last tier)" do
        expect(described_class.fee_cents_for(15000)).to eq(2100)
      end
    end

    context "beyond all tiers" do
      it "returns last tier fee (2100) for weight exceeding 15000g" do
        expect(described_class.fee_cents_for(15001)).to eq(2100)
      end

      it "returns last tier fee (2100) for very high weight" do
        expect(described_class.fee_cents_for(999_999)).to eq(2100)
      end
    end

    context "multi-product cart weight sums" do
      it "handles sum of two products within a tier" do
        # 100g + 100g = 200g → first tier (700 cents)
        expect(described_class.fee_cents_for(100 + 100)).to eq(700)
      end

      it "handles sum that crosses a tier boundary" do
        # 200g + 100g = 300g → second tier (800 cents)
        expect(described_class.fee_cents_for(200 + 100)).to eq(800)
      end

      it "handles sum of multiple products reaching a mid-range tier" do
        # 3 × 700g = 2100g → 2001–3000g tier (1100 cents)
        expect(described_class.fee_cents_for(700 * 3)).to eq(1100)
      end

      it "handles zero-weight products" do
        expect(described_class.fee_cents_for(0)).to eq(700)
      end

      it "applies default product weight (2000g) correctly" do
        # Produit#set_default_poids defaults to 2000g → 1001–2000g tier (1000 cents)
        expect(described_class.fee_cents_for(2000)).to eq(1000)
      end
    end
  end
end
