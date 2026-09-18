# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::StripeTotals do
  let(:stripe_scope) { StripePayment.none }

  subject(:totals) do
    described_class.new(
      datedebut: Date.new(2026, 8, 1),
      datefin: Date.new(2026, 9, 15),
      stripe_payments_scope: stripe_scope
    )
  end

  describe "#total_eur" do
    it "returns 0 for an empty commande_ids list" do
      expect(totals.total_eur(commande_ids: [])).to eq(0)
    end

    it "scopes Stripe totals to the given commande_ids" do
      allow(stripe_scope).to receive(:where).with(commande_id: [42]).and_return(stripe_scope)
      allow(stripe_scope).to receive(:sum).with(:amount).and_return(12_500)
      allow(totals).to receive(:remboursements_eur).with(commande_ids: [42]).and_return(5.to_d)

      expect(totals.total_eur(commande_ids: [42])).to eq(120.to_d)
      expect(stripe_scope).to have_received(:where).with(commande_id: [42])
    end
  end
end
