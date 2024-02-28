class DropMessagemails < ActiveRecord::Migration[7.1]
  def change
    drop_table :messagemails
  end
end
