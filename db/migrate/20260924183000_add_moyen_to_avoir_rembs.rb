# frozen_string_literal: true

class AddMoyenToAvoirRembs < ActiveRecord::Migration[7.1]
  def change
    add_column :avoir_rembs, :moyen, :string
  end
end
