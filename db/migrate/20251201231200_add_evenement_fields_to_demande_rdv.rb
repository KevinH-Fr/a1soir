class AddEvenementFieldsToDemandeRdv < ActiveRecord::Migration[7.1]
  def change
    add_column :demande_rdvs, :evenement, :string
    add_column :demande_rdvs, :date_evenement, :date
  end
end
