class AddCgvAcceptedAtToStripePayments < ActiveRecord::Migration[7.1]
  def change
    add_column :stripe_payments, :cgv_accepted_at, :datetime
  end
end
