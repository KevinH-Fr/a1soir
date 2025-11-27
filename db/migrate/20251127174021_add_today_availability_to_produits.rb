class AddTodayAvailabilityToProduits < ActiveRecord::Migration[7.1]
  def change
    add_column :produits, :today_availability, :boolean, default: false, null: false
    
    # Index pour améliorer les performances des requêtes de filtrage
    add_index :produits, :today_availability
  end
end
