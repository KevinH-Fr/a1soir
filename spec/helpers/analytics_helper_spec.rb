# frozen_string_literal: true

require "rails_helper"

RSpec.describe AnalyticsHelper, type: :helper do
  let(:categorie) { CategorieProduit.create!(nom: "Costumes") }
  let(:client) do
    Client.create!(
      nom: "Durand",
      prenom: "Alice",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "analytics-ga4-#{SecureRandom.hex(4)}@test.com"
    )
  end
  let(:profile) { Profile.create!(prenom: "Vendeur", nom: "Analytics") }
  let(:produit) do
    Produit.create!(
      nom: "Veste costume 441100/82",
      prixvente: 695,
      stripe_price_id: "price_ga4_001",
      eshop: true,
      today_availability: true,
      quantite: 1
    ).tap { |p| p.categorie_produits << categorie }
  end

  def create_eshop_commande
    Commande.create!(
      client: client,
      profile: profile,
      nom: "E-shop GA4",
      montant: 100,
      devis: false,
      type_locvente: "vente",
      eshop: true
    )
  end

  describe "#ga4_item_from_produit" do
    it "builds a GA4 item hash" do
      item = helper.ga4_item_from_produit(produit)

      expect(item).to include(
        item_id: "produit-#{produit.id}",
        item_name: produit.nom,
        item_brand: "Autour D'Un Soir",
        item_category: categorie.nom,
        price: 695.0,
        quantity: 1
      )
    end
  end

  describe "#ga4_begin_checkout_payload" do
    it "sums cart value and lists items" do
      produit_b = Produit.create!(
        nom: "Noeud papillon",
        prixvente: 20,
        stripe_price_id: "price_ga4_002",
        eshop: true,
        today_availability: true,
        quantite: 1
      )

      payload = helper.ga4_begin_checkout_payload([produit, produit_b])

      expect(payload[:currency]).to eq("EUR")
      expect(payload[:value]).to eq(715.0)
      expect(payload[:items].size).to eq(2)
    end
  end

  describe "#ga4_purchase_payload" do
    it "includes transaction_id, value and line items" do
      commande = create_eshop_commande
      payment = StripePayment.create!(
        stripe_payment_id: "pi_ga4_test",
        amount: 71_500,
        currency: "eur",
        status: "paid",
        commande: commande
      )
      StripePaymentItem.create!(
        stripe_payment: payment,
        produit: produit,
        quantity: 1,
        unit_amount: 69_500
      )

      payload = helper.ga4_purchase_payload(payment)

      expect(payload[:transaction_id]).to eq(commande.ref_commande)
      expect(payload[:currency]).to eq("EUR")
      expect(payload[:value]).to eq(715.0)
      expect(payload[:items].first).to include(
        item_id: "produit-#{produit.id}",
        price: 695.0,
        quantity: 1
      )
    end
  end

  describe "#ga4_track_purchase_event" do
    it "returns payload once per payment id in session" do
      commande = create_eshop_commande
      payment = StripePayment.create!(
        stripe_payment_id: "pi_ga4_track",
        amount: 50_00,
        currency: "eur",
        status: "paid",
        commande: commande
      )
      StripePaymentItem.create!(
        stripe_payment: payment,
        produit: produit,
        quantity: 1,
        unit_amount: 50_00
      )
      session = {}

      first = helper.ga4_track_purchase_event(payment, session)
      second = helper.ga4_track_purchase_event(payment, session)

      expect(first).to be_present
      expect(second).to be_nil
      expect(session[:ga4_purchase_tracked_ids]).to eq([payment.id])
    end

    it "returns nil when payment is not paid" do
      payment = StripePayment.create!(
        stripe_payment_id: "pi_ga4_unpaid",
        amount: 50_00,
        currency: "eur",
        status: "pending"
      )

      expect(helper.ga4_track_purchase_event(payment, {})).to be_nil
    end

    it "does not mark session when payload building fails" do
      commande = create_eshop_commande
      payment = StripePayment.create!(
        stripe_payment_id: "pi_ga4_broken",
        amount: 50_00,
        currency: "eur",
        status: "paid",
        commande: commande
      )
      session = {}

      expect(helper.ga4_track_purchase_event(payment, session)).to be_nil
      expect(session[:ga4_purchase_tracked_ids]).to be_nil
    end
  end

  describe "GA4 failure isolation" do
    it "returns nil instead of raising when produit is missing" do
      expect(helper.ga4_view_item_payload(nil)).to be_nil
    end

    it "logs and returns nil when an unexpected error occurs" do
      allow(helper).to receive(:ga4_item_from_produit).and_raise(StandardError, "boom")

      expect(Rails.logger).to receive(:warn).with(/\[GA4\] view_item skipped: StandardError boom/)
      expect(helper.ga4_view_item_payload(produit)).to be_nil
    end
  end

  describe "rendering _ga4_event partial" do
    before do
      allow(helper).to receive(:analytics_consent?).and_return(true)
    end

    it "outputs a Stimulus ga4-event element" do
      html = helper.render(
        partial: "public/shared/ga4_event",
        locals: { event_name: "view_item", payload: helper.ga4_view_item_payload(produit) }
      )

      expect(html).to include('data-controller="ga4-event"')
      expect(html).to include("view_item")
      expect(html).to include("Veste costume 441100/82")
    end

    it "renders nothing without analytics consent" do
      allow(helper).to receive(:analytics_consent?).and_return(false)

      html = helper.render(
        partial: "public/shared/ga4_event",
        locals: { event_name: "view_item", payload: helper.ga4_view_item_payload(produit) }
      )

      expect(html.strip).to be_empty
    end
  end
end
