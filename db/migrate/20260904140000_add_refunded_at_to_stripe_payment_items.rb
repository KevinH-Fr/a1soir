# frozen_string_literal: true

class AddRefundedAtToStripePaymentItems < ActiveRecord::Migration[7.1]
  def change
    add_column :stripe_payment_items, :refunded_at, :datetime
  end
end
