# frozen_string_literal: true

class Admin::StripePaymentsController < Admin::ApplicationController
  def index
    payments = StripePayment.order(created_at: :desc).includes(:commande, stripe_payment_items: :produit)
    @pagy, @stripe_payments = pagy(payments, items: 25)
  end
end
