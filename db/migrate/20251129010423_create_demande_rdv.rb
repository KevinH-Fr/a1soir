class CreateDemandeRdv < ActiveRecord::Migration[7.1]
  def change
    create_table :demande_rdvs do |t|
      t.string :nom
      t.string :email
      t.string :telephone
      t.text :commentaire
      t.datetime :date_rdv
      t.string :statut

      t.timestamps
    end
  end
end
