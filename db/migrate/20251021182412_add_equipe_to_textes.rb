class AddEquipeToTextes < ActiveRecord::Migration[7.1]
  def change
    add_column :textes, :equipe, :text
  end
end
