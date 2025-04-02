class StripePaymentItem < ApplicationRecord
    belongs_to :stripe_payment
    belongs_to :produit
end