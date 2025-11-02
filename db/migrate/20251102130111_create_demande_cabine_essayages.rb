class CreateDemandeCabineEssayages < ActiveRecord::Migration[7.1]
  def change
    create_table :demande_cabine_essayages do |t|
      t.string :prenom
      t.string :nom
      t.string :mail
      t.string :telephone
      t.string :evenement
      t.date :date_evenement
      t.string :statut
      t.text :commentaires

      t.timestamps
    end
  end
end
