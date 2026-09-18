# frozen_string_literal: true

# Données de développement local uniquement.
# Usage : bin/rails db:seed   (après db:migrate ou db:schema:load)
#
# Comptes :
#   admin@dev.a1soir.local   (admin)
#   vendeur@dev.a1soir.local (vendeur)
# Mot de passe : password  (ou variable SEED_DEV_PASSWORD)

if Rails.env.production?
  puts "[seeds] Ignoré en production."
  return
end

unless Rails.env.development?
  puts "[seeds] Réservé à l'environnement development (pas test)."
  return
end

load Rails.root.join("db/seeds/00_helpers.rb")

seed_files = Dir[Rails.root.join("db/seeds/[0-9]*_*.rb")].sort
seed_files.reject! { |path| File.basename(path) == "00_helpers.rb" }
seed_files.each { |path| load path }

puts "[seeds] Terminé (#{seed_files.size} fichiers)."
