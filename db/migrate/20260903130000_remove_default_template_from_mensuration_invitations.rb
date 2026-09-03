class RemoveDefaultTemplateFromMensurationInvitations < ActiveRecord::Migration[7.2]
  def change
    change_column_default :mensuration_invitations, :template, from: "femme", to: nil
  end
end
