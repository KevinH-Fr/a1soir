class CreateMessagemails < ActiveRecord::Migration[7.1]
  def change
    create_table :messagemails do |t|
      t.string :titre
      t.text :body
      t.text :commentaires
      t.references :commande, null: true, foreign_key: true
      t.references :client, null: true, foreign_key: true

      t.timestamps
    end
  end
end
