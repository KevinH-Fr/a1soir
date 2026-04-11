# frozen_string_literal: true

class Admin::StripePaymentsController < Admin::ApplicationController
  def index
    @stripe_payments_count = StripePayment.count
    payments = StripePayment.order(created_at: :desc).includes(:commande, stripe_payment_items: :produit)
    @pagy, @stripe_payments = pagy_countless(payments, items: 25)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
