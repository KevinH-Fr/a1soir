class CreateTailles < ActiveRecord::Migration[7.1]
  def change
    create_table :tailles do |t|
      t.string :nom

      t.timestamps
    end
  end
end
