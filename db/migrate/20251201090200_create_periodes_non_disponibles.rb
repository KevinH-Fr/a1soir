class CreatePeriodesNonDisponibles < ActiveRecord::Migration[7.1]
  def change
    create_table :periodes_non_disponibles do |t|
      t.references :parametre_rdv, null: false, foreign_key: true

      # Période de fermeture
      t.date :date_debut, null: false
      t.date :date_fin,   null: false

      # true = revient chaque année (on ignore l'année dans la logique métier)
      # false = période exceptionnelle pour cette plage de dates précise
      t.boolean :recurrence, null: false, default: false

      t.timestamps
    end
  end
end


