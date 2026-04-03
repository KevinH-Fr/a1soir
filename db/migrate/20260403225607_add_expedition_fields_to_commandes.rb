class AddExpeditionFieldsToCommandes < ActiveRecord::Migration[7.1]
  def change
    add_column :commandes, :numero_suivi, :string
    add_column :commandes, :expedie_le, :datetime
  end
end
