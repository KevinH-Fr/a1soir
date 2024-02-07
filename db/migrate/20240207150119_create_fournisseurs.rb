class CreateFournisseurs < ActiveRecord::Migration[7.1]
  def change
    create_table :fournisseurs do |t|
      t.string :nom
      t.string :tel
      t.string :mail
      t.string :contact
      t.string :site
      t.text :notes

      t.timestamps
    end
  end
end
