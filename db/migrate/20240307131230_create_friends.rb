class CreateFriends < ActiveRecord::Migration[7.1]
  def change
    create_table :friends do |t|
      t.string :nom
      t.integer :age

      t.timestamps
    end
  end
end
