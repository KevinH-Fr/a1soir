class AddCoefPrixAchatLocationToAdminParameters < ActiveRecord::Migration[7.1]
  def change
    add_column :admin_parameters, :coef_prix_achat_location, :decimal
  end
end
