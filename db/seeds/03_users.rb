# frozen_string_literal: true

Seeds::Helpers.log("03", "Utilisateurs Devise")

password = Seeds::Helpers::DEV_PASSWORD

[
  ["admin", "admin"],
  ["vendeur", "vendeur"]
].each do |local, role|
  email = Seeds::Helpers.seed_email(local)
  user = User.find_or_initialize_by(email: email)
  user.role = role
  user.password = password
  user.password_confirmation = password
  user.save!
  Seeds::Helpers.log("03", "  #{email} (#{role})")
end

Seeds::Helpers.log("03", "Mot de passe : #{password} (ou SEED_DEV_PASSWORD)")
