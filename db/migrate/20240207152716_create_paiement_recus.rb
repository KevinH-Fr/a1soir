class CreatePaiementRecus < ActiveRecord::Migration[7.1]
  def change
    create_table :paiement_recus do |t|
      t.string :typepaiement
      t.decimal :montant
      t.references :commande, null: false, foreign_key: true
      t.string :moyen
      t.text :commentaires

      t.timestamps
    end
  end
end
