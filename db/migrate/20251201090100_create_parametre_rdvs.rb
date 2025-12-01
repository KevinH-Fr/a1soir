class CreateParametreRdvs < ActiveRecord::Migration[7.1]
  def change
    create_table :parametre_rdvs do |t|
      t.string  :nom

      # Remplace MINUTES_PAR_PERSONNE_SUPP
      t.integer :minutes_par_personne_supp, null: false, default: 15

      # Nombre de RDV simultanés max par jour de semaine
      # (à interpréter dans le modèle, par exemple 1 = lundi, ..., 7 = dimanche)
      t.integer :nb_rdv_simultanes_lundi,    null: false, default: 2
      t.integer :nb_rdv_simultanes_mardi,    null: false, default: 2
      t.integer :nb_rdv_simultanes_mercredi, null: false, default: 2
      t.integer :nb_rdv_simultanes_jeudi,    null: false, default: 2
      t.integer :nb_rdv_simultanes_vendredi, null: false, default: 2
      t.integer :nb_rdv_simultanes_samedi,   null: false, default: 2
      t.integer :nb_rdv_simultanes_dimanche, null: false, default: 2

      # Créneaux horaires disponibles (mêmes pour tous les jours)
      # ex: "10:00,11:00,15:00,16:00,17:00"
      t.string :creneaux_horaires

      t.timestamps
    end
  end
end


