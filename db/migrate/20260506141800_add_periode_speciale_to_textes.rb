class AddPeriodeSpecialeToTextes < ActiveRecord::Migration[7.1]
  def change
    add_column :textes, :mode_periode_speciale, :boolean, default: false, null: false
    add_column :textes, :encart_periode_speciale_fr, :text
    add_column :textes, :encart_periode_speciale_en, :text
  end
end
