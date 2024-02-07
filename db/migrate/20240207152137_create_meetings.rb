class CreateMeetings < ActiveRecord::Migration[7.1]
  def change
    create_table :meetings do |t|
      t.string :nom
      t.date :datedebut
      t.date :datefin
      t.references :commande, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :lieu

      t.timestamps
    end
  end
end
