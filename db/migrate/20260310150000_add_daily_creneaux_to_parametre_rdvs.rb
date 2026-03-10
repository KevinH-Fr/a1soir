class AddDailyCreneauxToParametreRdvs < ActiveRecord::Migration[7.1]
  def change
    add_column :parametre_rdvs, :creneaux_lundi, :string
    add_column :parametre_rdvs, :creneaux_mardi, :string
    add_column :parametre_rdvs, :creneaux_mercredi, :string
    add_column :parametre_rdvs, :creneaux_jeudi, :string
    add_column :parametre_rdvs, :creneaux_vendredi, :string
    add_column :parametre_rdvs, :creneaux_samedi, :string
    add_column :parametre_rdvs, :creneaux_dimanche, :string
  end
end

