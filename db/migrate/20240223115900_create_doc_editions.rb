class CreateDocEditions < ActiveRecord::Migration[7.1]
  def change
    create_table :doc_editions do |t|
      t.references :commande, null: true, foreign_key: true
      t.string :doc_type
      t.string :edition_type
      t.text :commentaires

      t.timestamps
    end
  end
end
