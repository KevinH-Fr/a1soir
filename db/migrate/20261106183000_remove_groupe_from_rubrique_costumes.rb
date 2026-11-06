# frozen_string_literal: true

class RemoveGroupeFromRubriqueCostumes < ActiveRecord::Migration[7.1]
  def change
    remove_index :rubrique_costumes, name: "index_rubrique_costumes_on_groupe_and_position"
    remove_column :rubrique_costumes, :groupe, :string
  end
end
