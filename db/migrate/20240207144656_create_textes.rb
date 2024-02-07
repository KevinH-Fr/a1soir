class CreateTextes < ActiveRecord::Migration[7.1]
  def change
    create_table :textes do |t|
      t.string :titre

      t.timestamps
    end
  end
end
