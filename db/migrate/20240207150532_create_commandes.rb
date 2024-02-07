class CreateCommandes < ActiveRecord::Migration[7.1]
  def change
    create_table :commandes do |t|
      t.string :nom
      t.decimal :montant
      t.text :description
      t.references :client, null: false, foreign_key: true
      t.date :debutloc
      t.date :finloc
      t.date :dateevent
      t.string :statutarticles
      t.string :typeevent
      t.references :profile, null: false, foreign_key: true
      t.text :commentaires
      t.text :commentaires_doc
      t.boolean :location
      t.boolean :devis

      t.timestamps
    end
  end
end
