# frozen_string_literal: true

class AddEshopToCommandes < ActiveRecord::Migration[7.1]
  def change
    add_column :commandes, :eshop, :boolean, default: false, null: false
  end
end
