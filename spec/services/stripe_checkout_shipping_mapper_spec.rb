# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe StripeCheckoutShippingMapper do
  let(:mock_address) do
    OpenStruct.new(
      line1: "10 rue de la Paix",
      line2: nil,
      city: "Paris",
      postal_code: "75002",
      country: "FR"
    )
  end

  let(:mock_shipping_details) do
    OpenStruct.new(name: "Marie Curie", address: mock_address)
  end

  let(:mock_customer_details) do
    OpenStruct.new(phone: "+33612345678")
  end

  let(:mock_session) do
    OpenStruct.new(
      shipping_details: mock_shipping_details,
      customer_details: mock_customer_details
    )
  end

  describe ".stripe_payment_shipping_attrs" do
    it "maps shipping and phone to payment attributes" do
      attrs = described_class.stripe_payment_shipping_attrs(mock_session)
      expect(attrs[:shipping_name]).to eq("Marie Curie")
      expect(attrs[:shipping_address_line1]).to eq("10 rue de la Paix")
      expect(attrs[:shipping_city]).to eq("Paris")
      expect(attrs[:shipping_postal_code]).to eq("75002")
      expect(attrs[:shipping_country]).to eq("FR")
      expect(attrs[:customer_phone]).to eq("+33612345678")
    end
  end

  describe ".client_address_attrs" do
    it "builds client fields from the session" do
      attrs = described_class.client_address_attrs(mock_session, nil)
      expect(attrs[:adresse]).to eq("10 rue de la Paix")
      expect(attrs[:cp]).to eq("75002")
      expect(attrs[:ville]).to eq("Paris")
      expect(attrs[:pays]).to eq("FR")
      expect(attrs[:tel]).to eq("+33612345678")
    end

    it "falls back to StripePayment when the session has no shipping" do
      payment = StripePayment.new(
        shipping_address_line1: "2 av. Test",
        shipping_city: "Lyon",
        shipping_postal_code: "69001",
        shipping_country: "FR",
        customer_phone: "+33400000000"
      )
      attrs = described_class.client_address_attrs(OpenStruct.new, payment)
      expect(attrs[:adresse]).to eq("2 av. Test")
      expect(attrs[:ville]).to eq("Lyon")
      expect(attrs[:tel]).to eq("+33400000000")
    end
  end

  describe ".commande_shipping_comment" do
    it "formats a single-line livraison comment" do
      payment = StripePayment.new(
        shipping_name: "Jean Dupont",
        shipping_address_line1: "1 rue A",
        shipping_postal_code: "31000",
        shipping_city: "Toulouse",
        shipping_country: "FR",
        customer_phone: "+33555555555"
      )
      expect(described_class.commande_shipping_comment(payment)).to include("Livraison:")
      expect(described_class.commande_shipping_comment(payment)).to include("Jean Dupont")
      expect(described_class.commande_shipping_comment(payment)).to include("Toulouse")
    end
  end

  describe ".placeholder_eshop_client?" do
    it "detects the default eshop placeholder" do
      c = Client.new(prenom: "Client", nom: "E-shop")
      expect(described_class.placeholder_eshop_client?(c)).to be(true)
    end
  end
end
