class CreateTypeProduits < ActiveRecord::Migration[7.1]
  def change
    create_table :type_produits do |t|
      t.string :nom

      t.timestamps
    end
  end
end
