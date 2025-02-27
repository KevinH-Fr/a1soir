class StripePayment < ApplicationRecord
  belongs_to :produit

  validates :stripe_payment_id, presence: true, uniqueness: true

end
