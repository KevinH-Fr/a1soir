# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe StripeCheckoutFulfillmentService do
  before do
    allow(StripePaymentMailer).to receive(:confirmation).and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: true))
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
  end
end
