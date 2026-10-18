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

  describe "rendering _meta_pixel partial" do
    it "loads the Meta pixel and tracks PageView on turbo visits" do
      allow(helper).to receive(:analytics_consent?).and_return(true)

      html = helper.render(partial: "public/shared/meta_pixel")

      expect(html).to include("https://connect.facebook.net/en_US/fbevents.js")
      expect(html).to include("fbq('init', '1754041385657389')")
      expect(html).to include("fbq('track', 'PageView')")
      expect(html).to include("turbo:load")
      expect(html).to include("https://www.facebook.com/tr?id=1754041385657389&ev=PageView&noscript=1")
    end

    it "renders nothing without analytics consent" do
      allow(helper).to receive(:analytics_consent?).and_return(false)

      expect(helper.render(partial: "public/shared/meta_pixel").strip).to be_empty
    end

    it "renders nothing in development" do
      allow(helper).to receive(:analytics_consent?).and_return(true)
      allow(Rails.env).to receive(:development?).and_return(true)

      expect(helper.render(partial: "public/shared/meta_pixel").strip).to be_empty
    end
  end

  describe "rendering _gtag partial" do
    it "declares Consent Mode before configuring the tags" do
      allow(helper).to receive(:analytics_consent?).and_return(true)

      html = helper.render(partial: "public/shared/gtag")

      expect(html).to include("gtag('consent', 'default'")
      expect(html).to include("ad_user_data: 'granted'")
      expect(html.index("gtag('consent'")).to be < html.index("gtag('config'")
    end

    it "renders nothing without analytics consent" do
      allow(helper).to receive(:analytics_consent?).and_return(false)

      expect(helper.render(partial: "public/shared/gtag").strip).to be_empty
    end
  end

  describe "#ga4_add_to_wishlist_payload" do
    it "builds the cabine payload like add_to_cart" do
      payload = helper.ga4_add_to_wishlist_payload(produit)

      expect(payload[:currency]).to eq("EUR")
      expect(payload[:value]).to eq(695.0)
      expect(payload[:items].first[:item_id]).to eq("produit-#{produit.id}")
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

  describe "#ga4_consume_form_event" do
    it "returns the remembered event once" do
      session = {}
      helper.ga4_remember_form_event("message_send", session)

      expect(helper.ga4_consume_form_event("message_send", session)).to eq("message_send")
      expect(helper.ga4_consume_form_event("message_send", session)).to be_nil
      expect(session).not_to have_key(:ga4_pending_form_events)
    end

    it "keeps other pending events" do
      session = {}
      helper.ga4_remember_form_event("message_send", session)
      helper.ga4_remember_form_event("request_appointment", session)

      helper.ga4_consume_form_event("message_send", session)

      expect(session[:ga4_pending_form_events]).to eq(["request_appointment"])
    end

    it "ignores unknown events" do
      session = {}
      helper.ga4_remember_form_event("generate_lead", session)

      expect(session).not_to have_key(:ga4_pending_form_events)
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

  describe "#meta_pixel_track" do
    it "maps a product view to ViewContent with the catalogue id" do
      track = helper.meta_pixel_track("view_item", helper.ga4_view_item_payload(produit))

      expect(track[:event_name]).to eq("ViewContent")
      expect(track[:event_id]).to be_nil
      expect(track[:payload]).to include(
        content_ids: ["produit-#{produit.id}"],
        content_type: "product",
        content_name: produit.nom,
        value: 695.0,
        currency: "EUR"
      )
      expect(track[:payload][:contents].first).to include(id: "produit-#{produit.id}", quantity: 1, item_price: 695.0)
    end

    it "maps cart, cabine and checkout events" do
      expect(helper.meta_pixel_track("add_to_cart", helper.ga4_add_to_cart_payload(produit))[:event_name]).to eq("AddToCart")
      expect(helper.meta_pixel_track("add_to_wishlist", helper.ga4_add_to_wishlist_payload(produit))[:event_name]).to eq("AddToWishlist")

      checkout = helper.meta_pixel_track("begin_checkout", helper.ga4_begin_checkout_payload([produit]))
      expect(checkout[:event_name]).to eq("InitiateCheckout")
      expect(checkout[:payload][:num_items]).to eq(1)
    end

    it "maps a purchase and keeps the order id for deduplication" do
      payload = {
        transaction_id: "CMD-1",
        currency: "EUR",
        value: 695.0,
        items: [helper.ga4_item_from_produit(produit)]
      }

      track = helper.meta_pixel_track("purchase", payload)

      expect(track[:event_name]).to eq("Purchase")
      expect(track[:event_id]).to eq("CMD-1")
      expect(track[:payload][:content_ids]).to eq(["produit-#{produit.id}"])
      expect(track[:payload][:num_items]).to eq(1)
    end

    it "ignores events that are not catalogue events" do
      expect(helper.meta_pixel_track("message_send", { currency: "EUR", value: 0, items: [] })).to be_nil
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
      expect(html).to include("ViewContent")
      expect(html).to include("produit-#{produit.id}")
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
