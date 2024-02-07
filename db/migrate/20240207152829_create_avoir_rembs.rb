class CreateAvoirRembs < ActiveRecord::Migration[7.1]
  def change
    create_table :avoir_rembs do |t|
      t.string :type_avoir_remb
      t.decimal :montant
      t.string :nature
      t.references :commande, null: false, foreign_key: true

      t.timestamps
    end
  end
end
