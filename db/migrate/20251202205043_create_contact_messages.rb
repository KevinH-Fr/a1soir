class CreateContactMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :contact_messages do |t|
      t.string :prenom
      t.string :nom
      t.string :email
      t.string :telephone
      t.string :sujet
      t.text :message

      t.timestamps
    end
  end
end
