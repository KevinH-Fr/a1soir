class StripePayment < ApplicationRecord
  belongs_to :produit, optional: true # kept for legacy/backward compatibility
  has_many :stripe_payment_items, dependent: :destroy

  validates :stripe_payment_id, presence: true, uniqueness: true
end