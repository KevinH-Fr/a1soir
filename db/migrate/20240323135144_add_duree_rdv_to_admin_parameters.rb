class AddDureeRdvToAdminParameters < ActiveRecord::Migration[7.1]
  def change
    add_column :admin_parameters, :duree_rdv, :integer
  end
end
