# frozen_string_literal: true

class RenameProduitCatalogueValues < ActiveRecord::Migration[7.1]
  def up
    change_column_default :produits, :catalogue, from: "boutique", to: "tenues_mariage_soiree"
    execute <<~SQL.squish
      UPDATE produits
      SET catalogue = 'tenues_mariage_soiree'
      WHERE catalogue = 'boutique'
    SQL
    execute <<~SQL.squish
      UPDATE produits
      SET catalogue = 'costume_epoque_deguisements'
      WHERE catalogue = 'costume'
    SQL
  end

  def down
    change_column_default :produits, :catalogue, from: "tenues_mariage_soiree", to: "boutique"
    execute <<~SQL.squish
      UPDATE produits
      SET catalogue = 'boutique'
      WHERE catalogue = 'tenues_mariage_soiree'
    SQL
    execute <<~SQL.squish
      UPDATE produits
      SET catalogue = 'costume'
      WHERE catalogue = 'costume_epoque_deguisements'
    SQL
  end
end
