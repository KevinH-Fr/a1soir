class CreateMensurationInvitations < ActiveRecord::Migration[7.2]
  def change
    create_table :mensuration_invitations do |t|
      t.string :email, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.string :template, null: false, default: "femme"
      t.string :locale, null: false, default: "fr"
      t.string :prenom
      t.string :nom
      # Message libre de l'admin, repris tel quel dans le mail d'invitation.
      t.text :message_perso
      # OTP stocké hashé uniquement (jamais en clair).
      t.string :otp_digest
      t.datetime :otp_sent_at
      t.integer :otp_attempts, null: false, default: 0
      t.string :status, null: false, default: "sent"
      t.references :client, foreign_key: true

      t.timestamps
    end

    add_index :mensuration_invitations, :token, unique: true
    add_index :mensuration_invitations, :email
  end
end
