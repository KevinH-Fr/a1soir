class CreateDemandeCabineEssayageItems < ActiveRecord::Migration[7.1]
  def change
    create_table :demande_cabine_essayage_items do |t|
      t.references :demande_cabine_essayage, null: false, foreign_key: true
      t.references :produit, null: false, foreign_key: true

      t.timestamps
    end
  end
end
