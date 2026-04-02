class StripePaymentItem < ApplicationRecord
  belongs_to :stripe_payment
  belongs_to :produit

  after_commit :update_produit_availability_if_paid, on: :create

  private

  def update_produit_availability_if_paid
    produit&.update_today_availability if stripe_payment&.status == "paid"
  end
end
