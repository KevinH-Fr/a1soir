class AddTailleIdToProduits < ActiveRecord::Migration[7.1]
  def change
    add_reference :produits, :taille, null: true, foreign_key: true
  end
end
