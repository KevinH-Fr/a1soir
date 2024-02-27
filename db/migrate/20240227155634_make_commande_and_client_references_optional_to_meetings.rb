class MakeCommandeAndClientReferencesOptionalToMeetings < ActiveRecord::Migration[7.1]
  def change
    change_column :meetings, :commande_id, :bigint, null: true
    change_column :meetings, :client_id, :bigint, null: true
  end

end
