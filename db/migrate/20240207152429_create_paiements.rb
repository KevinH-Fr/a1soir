class CreatePaiements < ActiveRecord::Migration[7.1]
  def change
    create_table :paiements do |t|
      t.string :typepaiement
      t.decimal :montant
      t.references :commande, null: false, foreign_key: true
      t.string :moyen
      t.text :commentaires

      t.timestamps
    end
  end
end
