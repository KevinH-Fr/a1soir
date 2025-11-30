class AddPrenomToDemandeRdvs < ActiveRecord::Migration[7.1]
  def change
    add_column :demande_rdvs, :prenom, :string
  end
end
