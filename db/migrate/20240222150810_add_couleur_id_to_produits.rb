class AddCouleurIdToProduits < ActiveRecord::Migration[7.1]
  def change
    add_reference :produits, :couleur, null: true, foreign_key: true
  end
end
