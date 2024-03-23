class ChangeCoefPrixAchatVenteToAdminParameters < ActiveRecord::Migration[7.1]
  def change
    rename_column :admin_parameters, :coef_prix_achat_location, :coef_prix_achat_vente
  end
end
