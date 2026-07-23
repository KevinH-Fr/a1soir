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

  describe "#total_poids_grammes" do
    let!(:produit_a) { Produit.create!(nom: "Robe A poids", quantite: 1, poids: 800) }
    let!(:produit_b) { Produit.create!(nom: "Robe B poids", quantite: 1, poids: 450) }

    def payment_with_items(items)
      StripePayment.create!(
        stripe_payment_id: "pi_poids_#{SecureRandom.hex(4)}",
        amount: 5000,
        currency: "eur",
        status: "paid"
      ).tap do |payment|
        items.each do |produit, qty|
          StripePaymentItem.create!(stripe_payment: payment, produit: produit, quantity: qty, unit_amount: 5000)
        end
      end
    end

    it "sums product weights multiplied by line quantities" do
      payment = payment_with_items([[produit_a, 1], [produit_b, 2]])
      expect(payment.total_poids_grammes).to eq(800 + (450 * 2))
    end

    it "falls back to commande articles when payment items are missing" do
      profile = Profile.create!(prenom: "V", nom: "Shop")
      client = Client.create!(prenom: "A", nom: "B", mail: "poids-fallback@example.com")
      commande = Commande.create!(
        client: client,
        profile: profile,
        nom: "E-shop",
        montant: 50,
        devis: false,
        type_locvente: "vente",
        typeevent: Commande::EVENEMENTS_OPTIONS.first,
        eshop: true
      )
      Article.create!(commande: commande, produit: produit_a, quantite: 2, prix: 50, total: 100, locvente: "vente")
      payment = StripePayment.create!(
        stripe_payment_id: "pi_legacy_poids_#{SecureRandom.hex(4)}",
        amount: 5000,
        currency: "eur",
        status: "paid",
        commande: commande
      )

      expect(payment.total_poids_grammes).to eq(1600)
    end
  end
end
