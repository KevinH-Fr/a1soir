# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripePayment, type: :model do
  describe "validations" do
    it "allows multiple rows with nil checkout session id (legacy)" do
      StripePayment.create!(
        stripe_payment_id: "pi_legacy_a",
        amount: 1000,
        currency: "eur",
        status: "paid",
        payment_method: "card",
        charge_id: "pi_legacy_a"
      )
      StripePayment.create!(
        stripe_payment_id: "pi_legacy_b",
        amount: 2000,
        currency: "eur",
        status: "paid",
        payment_method: "card",
        charge_id: "pi_legacy_b"
      )
      expect(StripePayment.count).to eq(2)
    end

    it "enforces unique stripe_checkout_session_id when set" do
      StripePayment.create!(
        stripe_payment_id: "pi_1",
        stripe_checkout_session_id: "cs_unique_1",
        amount: 1000,
        currency: "eur",
        status: "paid",
        payment_method: "card",
        charge_id: "pi_1"
      )
      dup = StripePayment.new(
        stripe_payment_id: "pi_2",
        stripe_checkout_session_id: "cs_unique_1",
        amount: 1000,
        currency: "eur",
        status: "paid",
        payment_method: "card",
        charge_id: "pi_2"
      )
      expect(dup).not_to be_valid
    end
  end

  describe ".a_expedier" do
    let!(:profile) { Profile.create!(prenom: "Vendeur", nom: "Boutique") }
    let!(:client) { Client.create!(prenom: "Alice", nom: "Test", mail: "alice-scope@example.com") }

    def payment_with_commande(expedie_le:, status: "paid")
      commande = Commande.create!(
        client: client,
        profile: profile,
        nom: "E-shop",
        montant: 50,
        devis: false,
        type_locvente: "vente",
        typeevent: Commande::EVENEMENTS_OPTIONS.first,
        eshop: true,
        expedie_le: expedie_le
      )
      StripePayment.create!(
        stripe_payment_id: "pi_#{SecureRandom.hex(6)}",
        amount: 5000,
        currency: "eur",
        status: status,
        commande: commande
      )
    end

    it "includes paid payments whose commande is not shipped yet" do
      pending = payment_with_commande(expedie_le: nil)
      expect(described_class.a_expedier).to contain_exactly(pending)
    end

    it "excludes payments whose commande has expedie_le set" do
      payment_with_commande(expedie_le: 1.day.ago)
      expect(described_class.a_expedier).to be_empty
    end

    it "excludes non-paid payments" do
      payment_with_commande(expedie_le: nil, status: "pending")
      expect(described_class.a_expedier).to be_empty
    end

    it "excludes payments without a commande" do
      StripePayment.create!(
        stripe_payment_id: "pi_orphan_#{SecureRandom.hex(4)}",
        amount: 1000,
        currency: "eur",
        status: "paid"
      )
      expect(described_class.a_expedier).to be_empty
    end
  end
end
