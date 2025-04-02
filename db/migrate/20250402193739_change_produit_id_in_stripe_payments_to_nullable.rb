class ChangeProduitIdInStripePaymentsToNullable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :stripe_payments, :produit_id, true
  end
end
