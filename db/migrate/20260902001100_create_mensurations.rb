class CreateMensurations < ActiveRecord::Migration[7.2]
  def change
    create_table :mensurations do |t|
      t.references :mensuration_invitation, null: false, foreign_key: true, index: { unique: true }
      t.references :client, foreign_key: true
      # Identité saisie par le client (snapshot du formulaire ; le Client reste la référence admin).
      t.string :prenom
      t.string :nom
      t.string :telephone
      t.string :adresse
      t.string :cp
      t.string :ville
      t.date :date_evenement
      # Mesures en JSON : les jeux de champs femme/homme diffèrent (voir config/mensuration_fields.yml).
      t.json :measurements, null: false, default: {}
      t.string :template, null: false
      t.string :locale, null: false, default: "fr"

      t.timestamps
    end
  end
end
