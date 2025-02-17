class AddContentToTextes < ActiveRecord::Migration[7.1]
  def change
    add_column :textes, :adresse, :string
    add_column :textes, :contact, :text
    add_column :textes, :horaire, :text
  end
end
