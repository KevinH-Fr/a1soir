class CreateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :profiles do |t|
      t.string :prenom
      t.string :nom

      t.timestamps
    end
  end
end
