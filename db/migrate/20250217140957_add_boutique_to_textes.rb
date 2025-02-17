class AddBoutiqueToTextes < ActiveRecord::Migration[7.1]
  def change
    add_column :textes, :boutique, :text
  end
end
