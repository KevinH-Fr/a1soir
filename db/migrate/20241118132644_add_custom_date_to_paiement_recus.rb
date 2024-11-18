class AddCustomDateToPaiementRecus < ActiveRecord::Migration[7.1]
  def change
    add_column :paiement_recus, :custom_date, :date
  end
end
