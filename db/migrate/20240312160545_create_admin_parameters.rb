class CreateAdminParameters < ActiveRecord::Migration[7.1]
  def change
    create_table :admin_parameters do |t|
      t.integer :tx_tva

      t.timestamps
    end
  end
end
