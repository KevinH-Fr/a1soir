class AddLanguageToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :language, :string, default:"fr"
  end
end
