# frozen_string_literal: true

# Données de développement local uniquement.
# Usage :
#   bin/rails db:seed                              # inclut 09_stripe_eshop (API Stripe test)
#   SEED_ONLY=05_catalogue,06_clients_commandes bin/rails db:seed
#   bin/rails seeds:run[05_catalogue]
#   bin/rails seeds:run[09_stripe_eshop]
#   bin/rails seeds:list
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

if ENV["SEED_ONLY"].present?
  wanted = ENV["SEED_ONLY"].split(",").map(&:strip).reject(&:blank?)
  seed_files = wanted.map do |name|
    basename = name.sub(/\.rb\z/, "")
    path = Rails.root.join("db/seeds/#{basename}.rb")
    path = Dir[Rails.root.join("db/seeds/#{basename}*.rb")].min unless path.exist?
    path = Dir[Rails.root.join("db/seeds/*#{basename}*.rb")].min if path.blank? || !File.exist?(path)
    raise "[seeds] SEED_ONLY introuvable : #{name}" if path.blank? || !File.exist?(path)

    path.to_s
  end
end

seed_files.each { |path| load path }

puts "[seeds] Terminé (#{seed_files.size} fichiers)."
