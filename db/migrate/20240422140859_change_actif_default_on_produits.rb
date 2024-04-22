class ChangeActifDefaultOnProduits < ActiveRecord::Migration[7.1]
  def change
    change_column_default :produits, :actif, from: nil, to: true
  end
end
