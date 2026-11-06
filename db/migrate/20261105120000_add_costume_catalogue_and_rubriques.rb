# frozen_string_literal: true

class AddCostumeCatalogueAndRubriques < ActiveRecord::Migration[7.1]
  def change
    add_column :produits, :catalogue, :string, null: false, default: "boutique"
    add_index :produits, :catalogue

    create_table :rubrique_costumes do |t|
      t.string :nom, null: false
      t.string :groupe, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :rubrique_costumes, :nom, unique: true
    add_index :rubrique_costumes, [:groupe, :position]

    create_table :produits_rubrique_costumes, id: false do |t|
      t.integer :produit_id, null: false
      t.integer :rubrique_costume_id, null: false
    end
    add_index :produits_rubrique_costumes, :produit_id
    add_index :produits_rubrique_costumes, :rubrique_costume_id
    add_index :produits_rubrique_costumes,
              [:produit_id, :rubrique_costume_id],
              unique: true,
              name: "index_produits_rubriques_on_produit_and_rubrique"
  end
end
