class StripePaymentItem < ApplicationRecord
  belongs_to :stripe_payment
  belongs_to :produit

  scope :not_refunded, -> { where(refunded_at: nil) }

  after_commit :update_produit_availability_if_paid, on: [:create, :update]

  def refunded?
    refunded_at.present?
  end

  private

  def update_produit_availability_if_paid
    produit&.update_today_availability if stripe_payment&.status == "paid"
  end
end

