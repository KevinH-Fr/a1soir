# frozen_string_literal: true

class AddLocaleToDemandeRdvs < ActiveRecord::Migration[7.1]
  def change
    add_column :demande_rdvs, :locale, :string, default: "fr", null: false
  end
end
