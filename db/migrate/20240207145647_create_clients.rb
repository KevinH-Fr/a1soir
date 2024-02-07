class CreateClients < ActiveRecord::Migration[7.1]
  def change
    create_table :clients do |t|
      t.string :prenom
      t.string :nom
      t.text :commentaires
      t.string :propart
      t.string :intitule
      t.string :tel
      t.string :tel2
      t.string :mail
      t.string :mail2
      t.string :adresse
      t.string :cp
      t.string :ville
      t.string :pays
      t.string :contact

      t.timestamps
    end
  end
end
