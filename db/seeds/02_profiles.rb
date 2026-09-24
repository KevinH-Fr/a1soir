# frozen_string_literal: true

Seeds::Helpers.log("02", "Profils vendeurs")

profile_admin = Profile.find_or_initialize_by(id: Profile::ADMIN_PROFILE_ID)
profile_admin.assign_attributes(prenom: "Admin", nom: "Technique")
profile_admin.save!

Profile.find_or_create_by!(prenom: "Marie", nom: "Dupont")
Profile.find_or_create_by!(prenom: "Paul", nom: "Martin")
# Comme en prod : prénom « Eshop », nom vide (commandes Stripe / e-shop).
Profile.find_or_create_by!(prenom: Profile::ESHOP_PROFILE_PRENOM) do |p|
  p.nom = nil
end
Seeds::Helpers.log("02", "Profil E-shop : #{Profile::ESHOP_PROFILE_PRENOM} (id #{Profile.find_by(prenom: Profile::ESHOP_PROFILE_PRENOM)&.id})")

Profile.find_or_create_by!(prenom: Profile::COMMANDE_RAPIDE_PROFILE_PRENOM) do |p|
  p.nom = nil
end
Seeds::Helpers.log("02", "Profil Commande rapide : #{Profile::COMMANDE_RAPIDE_PROFILE_PRENOM} (id #{Profile.find_by(prenom: Profile::COMMANDE_RAPIDE_PROFILE_PRENOM)&.id})")
