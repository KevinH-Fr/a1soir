# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripePaymentItem do
  let!(:produit) { Produit.create!(nom: "Produit callback test", quantite: 2) }

  let(:paid_payment) do
    StripePayment.create!(
      stripe_payment_id: "pi_item_paid_1",
      status: "paid",
      amount: 5000,
      currency: "eur"
    )
  end

  let(:pending_payment) do
    StripePayment.create!(
      stripe_payment_id: "pi_item_pending_1",
      status: "pending",
      amount: 5000,
      currency: "eur"
    )
  end

  describe "availability callback logic (#update_produit_availability_if_paid)" do
    it "calls update_today_availability on produit when payment is paid" do
      item = StripePaymentItem.new(stripe_payment: paid_payment, produit: produit, quantity: 1, unit_amount: 5000)
      expect(produit).to receive(:update_today_availability)
      item.send(:update_produit_availability_if_paid)
    end

    it "does not call update_today_availability when payment is pending" do
      item = StripePaymentItem.new(stripe_payment: pending_payment, produit: produit, quantity: 1, unit_amount: 5000)
      expect(produit).not_to receive(:update_today_availability)
      item.send(:update_produit_availability_if_paid)
    end

    it "does not call update_today_availability when produit is nil" do
      item = StripePaymentItem.new(stripe_payment: paid_payment, quantity: 1, unit_amount: 5000)
      # Should not raise — produit is nil, callback guards with &.
      expect { item.send(:update_produit_availability_if_paid) }.not_to raise_error
    end
  end

  describe "integration: today_availability reflects eshop sale after payment is paid" do
    it "sets produit today_availability to false after exhausting stock" do
      produit_single = Produit.create!(nom: "Item stock intégration", quantite: 1)
      payment = StripePayment.create!(stripe_payment_id: "pi_item_integ_1", status: "paid", amount: 5000, currency: "eur")
      StripePaymentItem.create!(stripe_payment: payment, produit: produit_single, quantity: 1, unit_amount: 5000)

      # Manually trigger availability update (simulates after_commit in transactional tests)
      produit_single.update_today_availability
      expect(produit_single.reload.today_availability).to be(false)
    end

    it "leaves today_availability true when pending payment items do not reduce stock" do
      payment = StripePayment.create!(stripe_payment_id: "pi_item_integ_2", status: "pending", amount: 5000, currency: "eur")
      StripePaymentItem.create!(stripe_payment: payment, produit: produit, quantity: 2, unit_amount: 5000)

      produit.update_today_availability
      expect(produit.reload.today_availability).to be(true)
    end
  end
end
