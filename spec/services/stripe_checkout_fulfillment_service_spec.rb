# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe StripeCheckoutFulfillmentService do
  let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("GMAIL_ACCOUNT").and_return(nil)
    allow(StripePaymentMailer).to receive(:confirmation).and_return(mail_delivery)
    allow(StripePaymentMailer).to receive(:notification_admin).and_return(mail_delivery)
  end

  let!(:profile) { Profile.create!(prenom: "Admin", nom: "Boutique") }

  let!(:produit) do
    Produit.create!(
      nom: "Robe test Stripe",
      prixvente: 50,
      stripe_price_id: "price_test_123",
      eshop: true,
      today_availability: true,
      quantite: 1
    )
  end

  let(:mock_price) { OpenStruct.new(id: "price_test_123", unit_amount: 5000) }
  let(:mock_line_item) { OpenStruct.new(price: mock_price, quantity: 1, amount_total: 5000) }
  let(:mock_line_items) { OpenStruct.new(data: [mock_line_item]) }

  let(:mock_session) do
    OpenStruct.new(
      id: "cs_test_fulfill_1",
      payment_status: "paid",
      payment_intent: "pi_test_fulfill_1",
      amount_total: 5000,
      currency: "eur",
      payment_method_types: ["card"],
      customer_email: "acheteur@example.com",
      customer_details: nil,
      line_items: mock_line_items
    )
  end

  describe "#fulfill!" do
    it "creates StripePayment, items, commande and articles" do
      expect do
        described_class.new(mock_session).fulfill!
      end.to change(StripePayment, :count).by(1)
        .and change(StripePaymentItem, :count).by(1)
        .and change(Commande, :count).by(1)
        .and change(Article, :count).by(1)
    end

    it "is idempotent for the same checkout session" do
      described_class.new(mock_session).fulfill!

      expect do
        described_class.new(mock_session).fulfill!
      end.not_to change(StripePayment, :count)

      expect do
        described_class.new(mock_session).fulfill!
      end.not_to change(StripePaymentItem, :count)

      expect do
        described_class.new(mock_session).fulfill!
      end.not_to change(Commande, :count)
    end

    it "does nothing when payment is not paid" do
      mock_session.payment_status = "unpaid"
      expect do
        described_class.new(mock_session).fulfill!
      end.not_to change(StripePayment, :count)
    end

    it "enqueues client confirmation email" do
      expect(StripePaymentMailer).to receive(:confirmation).with(an_instance_of(StripePayment)).and_return(mail_delivery)
      described_class.new(mock_session).fulfill!
    end

    it "does not enqueue admin notification when GMAIL_ACCOUNT is blank" do
      expect(StripePaymentMailer).not_to receive(:notification_admin)
      described_class.new(mock_session).fulfill!
    end

    it "enqueues admin notification when GMAIL_ACCOUNT is set" do
      allow(ENV).to receive(:[]).with("GMAIL_ACCOUNT").and_return("admin@example.com")
      expect(StripePaymentMailer).to receive(:notification_admin).with(an_instance_of(StripePayment)).and_return(mail_delivery)
      described_class.new(mock_session).fulfill!
    end

    it "enqueues only admin email when customer_email is missing but GMAIL_ACCOUNT is set" do
      allow(ENV).to receive(:[]).with("GMAIL_ACCOUNT").and_return("admin@example.com")
      mock_session.customer_email = nil
      expect(StripePaymentMailer).not_to receive(:confirmation)
      expect(StripePaymentMailer).to receive(:notification_admin).with(an_instance_of(StripePayment)).and_return(mail_delivery)
      described_class.new(mock_session).fulfill!
    end
  end

  # -------------------------------------------------------------------------
  # Multiple line items (two different products)
  # -------------------------------------------------------------------------

  describe "#fulfill! with multiple line items" do
    let!(:produit2) do
      Produit.create!(
        nom: "Jupe test Stripe",
        prixvente: 30,
        stripe_price_id: "price_test_456",
        eshop: true,
        today_availability: true,
        quantite: 2
      )
    end

    let(:mock_price2) { OpenStruct.new(id: "price_test_456", unit_amount: 3000) }
    let(:mock_line_item2) { OpenStruct.new(price: mock_price2, quantity: 1, amount_total: 3000) }

    let(:mock_session_multi) do
      OpenStruct.new(
        id: "cs_test_fulfill_multi",
        payment_status: "paid",
        payment_intent: "pi_test_fulfill_multi",
        amount_total: 8000,
        currency: "eur",
        payment_method_types: ["card"],
        customer_email: "acheteur_multi@example.com",
        customer_details: nil,
        line_items: OpenStruct.new(data: [mock_line_item, mock_line_item2]),
        metadata: nil
      )
    end

    it "creates one StripePaymentItem per line item" do
      expect do
        described_class.new(mock_session_multi).fulfill!
      end.to change(StripePaymentItem, :count).by(2)
    end

    it "creates one Commande with one Article per line item" do
      expect do
        described_class.new(mock_session_multi).fulfill!
      end.to change(Commande, :count).by(1)
        .and change(Article, :count).by(2)
    end
  end

  # -------------------------------------------------------------------------
  # Product variant: taille (size)
  # -------------------------------------------------------------------------

  describe "#fulfill! with a product that has a taille" do
    let!(:taille) { Taille.create!(nom: "M") }

    let!(:produit_taille) do
      Produit.create!(
        nom: "Robe avec taille",
        prixvente: 65,
        stripe_price_id: "price_taille_001",
        eshop: true,
        today_availability: true,
        quantite: 1,
        taille: taille
      )
    end

    let(:mock_price_taille) { OpenStruct.new(id: "price_taille_001", unit_amount: 6500) }
    let(:mock_line_item_taille) { OpenStruct.new(price: mock_price_taille, quantity: 1, amount_total: 6500) }

    let(:mock_session_taille) do
      OpenStruct.new(
        id: "cs_test_taille_001",
        payment_status: "paid",
        payment_intent: "pi_test_taille_001",
        amount_total: 6500,
        currency: "eur",
        payment_method_types: ["card"],
        customer_email: "taille@example.com",
        customer_details: nil,
        line_items: OpenStruct.new(data: [mock_line_item_taille]),
        metadata: nil
      )
    end

    it "links the StripePaymentItem to the correct produit (with taille)" do
      described_class.new(mock_session_taille).fulfill!
      item = StripePaymentItem.last
      expect(item.produit.taille).to eq(taille)
    end
  end

  # -------------------------------------------------------------------------
  # Product variant: couleur (colour)
  # -------------------------------------------------------------------------

  describe "#fulfill! with a product that has a couleur" do
    let!(:couleur) { Couleur.create!(nom: "rouge") }

    let!(:produit_couleur) do
      Produit.create!(
        nom: "Robe avec couleur",
        prixvente: 70,
        stripe_price_id: "price_couleur_001",
        eshop: true,
        today_availability: true,
        quantite: 1,
        couleur: couleur
      )
    end

    let(:mock_price_couleur) { OpenStruct.new(id: "price_couleur_001", unit_amount: 7000) }
    let(:mock_line_item_couleur) { OpenStruct.new(price: mock_price_couleur, quantity: 1, amount_total: 7000) }

    let(:mock_session_couleur) do
      OpenStruct.new(
        id: "cs_test_couleur_001",
        payment_status: "paid",
        payment_intent: "pi_test_couleur_001",
        amount_total: 7000,
        currency: "eur",
        payment_method_types: ["card"],
        customer_email: "couleur@example.com",
        customer_details: nil,
        line_items: OpenStruct.new(data: [mock_line_item_couleur]),
        metadata: nil
      )
    end

    it "links the StripePaymentItem to the correct produit (with couleur)" do
      described_class.new(mock_session_couleur).fulfill!
      item = StripePaymentItem.last
      expect(item.produit.couleur).to eq(couleur)
    end
  end

  # -------------------------------------------------------------------------
  # Two products — same type but different taille (variant matrix in one cart)
  # -------------------------------------------------------------------------

  describe "#fulfill! with two variants of the same product (different taille)" do
    let!(:taille_s) { Taille.create!(nom: "s") }
    let!(:taille_l) { Taille.create!(nom: "l") }

    let!(:produit_s) do
      Produit.create!(
        nom: "Robe variante",
        prixvente: 55,
        stripe_price_id: "price_var_s_001",
        eshop: true,
        today_availability: true,
        quantite: 1,
        taille: taille_s
      )
    end

    let!(:produit_l) do
      Produit.create!(
        nom: "Robe variante",
        prixvente: 55,
        stripe_price_id: "price_var_l_001",
        eshop: true,
        today_availability: true,
        quantite: 1,
        taille: taille_l
      )
    end

    let(:mock_li_s) { OpenStruct.new(price: OpenStruct.new(id: "price_var_s_001", unit_amount: 5500), quantity: 1, amount_total: 5500) }
    let(:mock_li_l) { OpenStruct.new(price: OpenStruct.new(id: "price_var_l_001", unit_amount: 5500), quantity: 1, amount_total: 5500) }

    let(:mock_session_variants) do
      OpenStruct.new(
        id: "cs_test_variants_001",
        payment_status: "paid",
        payment_intent: "pi_test_variants_001",
        amount_total: 11000,
        currency: "eur",
        payment_method_types: ["card"],
        customer_email: "variants@example.com",
        customer_details: nil,
        line_items: OpenStruct.new(data: [mock_li_s, mock_li_l]),
        metadata: nil
      )
    end

    it "creates a StripePaymentItem for each size variant" do
      expect do
        described_class.new(mock_session_variants).fulfill!
      end.to change(StripePaymentItem, :count).by(2)
    end

    it "creates one Article per variant in the Commande" do
      expect do
        described_class.new(mock_session_variants).fulfill!
      end.to change(Article, :count).by(2)
    end

    it "attaches each item to the correct taille produit" do
      described_class.new(mock_session_variants).fulfill!
      # Taille#nom is downcased on validation ("S" → "s", "L" → "l")
      tailles = StripePaymentItem.last(2).map { |i| i.produit.taille.nom }.sort
      expect(tailles).to eq(%w[l s])
    end
  end
end
