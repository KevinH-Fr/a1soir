# frozen_string_literal: true

namespace :seeds do
  desc "Charge un ou plusieurs fichiers de seed (ex: bin/rails seeds:run[05_catalogue] ou seeds:run[05_catalogue,09_stripe_eshop])"
  task :run, [:files] => :environment do |_t, args|
    if Rails.env.production?
      abort "[seeds] Interdit en production."
    end

    unless Rails.env.development?
      abort "[seeds] Réservé à development."
    end

    names = args[:files].to_s.split(",").map(&:strip).reject(&:blank?)
    if names.empty?
      abort <<~MSG
        Usage :
          bin/rails seeds:run[05_catalogue]
          bin/rails seeds:run[05_catalogue,09_stripe_eshop]
          bin/rails seeds:list
      MSG
    end

    load Rails.root.join("db/seeds/00_helpers.rb")

    names.each do |name|
      basename = name.sub(/\.rb\z/, "")
      path = Rails.root.join("db/seeds/#{basename}.rb")
      unless path.exist?
        # Accepte "5" ou "05" → premier fichier qui matche
        path = Dir[Rails.root.join("db/seeds/#{basename}*.rb")].min
        path ||= Dir[Rails.root.join("db/seeds/*#{basename}*.rb")].min
      end

      abort "[seeds] Fichier introuvable : #{name}" if path.blank? || !File.exist?(path)

      puts "[seeds] → #{File.basename(path)}"
      load path
    end

    puts "[seeds] Terminé (#{names.size} fichier(s))."
  end

  desc "Liste les fichiers de seed disponibles"
  task list: :environment do
    puts "Helpers : db/seeds/00_helpers.rb (chargé automatiquement)"
    Dir[Rails.root.join("db/seeds/[0-9]*_*.rb")].sort.each do |path|
      puts "  #{File.basename(path, ".rb")}"
    end
    puts
    puts "Exemples :"
    puts "  bin/rails db:seed"
    puts "  SEED_ONLY=05_catalogue bin/rails db:seed"
    puts "  bin/rails seeds:run[05_catalogue]"
    puts "  bin/rails seeds:run[09_stripe_eshop]"
  end
end
