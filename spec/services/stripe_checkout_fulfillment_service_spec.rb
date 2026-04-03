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
end
