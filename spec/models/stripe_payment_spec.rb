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
end
