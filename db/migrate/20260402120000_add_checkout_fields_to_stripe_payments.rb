# frozen_string_literal: true

class AddCheckoutFieldsToStripePayments < ActiveRecord::Migration[7.1]
  def change
    add_column :stripe_payments, :stripe_checkout_session_id, :string
    add_column :stripe_payments, :customer_email, :string
    add_column :stripe_payments, :confirmation_email_sent_at, :datetime
    add_reference :stripe_payments, :commande, foreign_key: true, null: true

    add_index :stripe_payments, :stripe_checkout_session_id, unique: true, where: "stripe_checkout_session_id IS NOT NULL"
  end
end
