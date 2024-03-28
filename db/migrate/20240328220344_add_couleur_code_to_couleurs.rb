class AddCouleurCodeToCouleurs < ActiveRecord::Migration[7.1]
  def change
    add_column :couleurs, :couleur_code, :string
  end
end
