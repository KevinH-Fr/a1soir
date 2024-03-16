class AddCoefLongueDureeToAdminParameters < ActiveRecord::Migration[7.1]
  def change
    add_column :admin_parameters, :coef_longue_duree, :integer
  end
end
