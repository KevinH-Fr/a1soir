class CreateCouleurs < ActiveRecord::Migration[7.1]
  def change
    create_table :couleurs do |t|
      t.string :nom

      t.timestamps
    end
  end
end
