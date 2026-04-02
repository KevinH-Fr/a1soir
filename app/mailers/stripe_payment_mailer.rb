# frozen_string_literal: true

class StripePaymentMailer < ApplicationMailer
  def confirmation(stripe_payment)
    @payment = stripe_payment
    @items = stripe_payment.stripe_payment_items.includes(:produit)
    mail(
      to: @payment.customer_email,
      subject: "Confirmation de votre achat A1soir"
    )
  end
end
