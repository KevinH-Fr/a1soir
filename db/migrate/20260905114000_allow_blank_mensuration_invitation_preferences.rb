class AllowBlankMensurationInvitationPreferences < ActiveRecord::Migration[7.2]
  def change
    change_column_null :mensuration_invitations, :template, true
    change_column_null :mensuration_invitations, :locale, true
    change_column_default :mensuration_invitations, :locale, from: "fr", to: nil
  end
end