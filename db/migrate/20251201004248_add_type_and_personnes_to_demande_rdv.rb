class AddTypeAndPersonnesToDemandeRdv < ActiveRecord::Migration[7.1]
  def change
    add_column :demande_rdvs, :type_rdv, :string
    add_column :demande_rdvs, :nombre_personnes, :integer
  end
end
