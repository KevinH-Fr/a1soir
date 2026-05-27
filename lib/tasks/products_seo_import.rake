# frozen_string_literal: true

require "csv"

namespace :products do
  desc "Import SEO product names from CSV"

  task :seo_import, [:csv_path] => :environment do |_t, args|
    source_label = nil

    csv_content =
      if args[:csv_path].present?
        csv_path = Rails.root.join(args[:csv_path])

        unless File.exist?(csv_path)
          abort "CSV introuvable : #{csv_path}"
        end

        source_label = csv_path.to_s
        File.read(csv_path)
      else
        source_label = "STDIN"
        STDIN.read
      end

    abort "CSV vide" if csv_content.blank?

    dry_run = ENV.fetch("DRY_RUN", "true") != "false"

    puts
    puts "======================================"
    puts "Products SEO Import"
    puts "ENV       : #{Rails.env}"
    puts "SOURCE    : #{source_label}"
    puts "DRY_RUN   : #{dry_run}"
    puts "======================================"
    puts

    rows = CSV.parse(csv_content, headers: true)

    approved_rows = rows.select do |r|
      r[0].to_s.strip.present? &&
        r[4].to_s.strip.downcase == "yes"
    end

    puts "Lignes total     : #{rows.size}"
    puts "Lignes approved  : #{approved_rows.size}"
    puts

    updated_count = 0
    skipped_count = 0
    stripe_count = 0
    error_count = 0

    approved_rows.each do |r|
      id = r[0].to_s.strip
      old_handle = r[1].to_s.strip
      old_nom = r[2].to_s.strip
      new_nom = r[3].to_s.strip

      if new_nom.blank?
        skipped_count += 1
        puts "[SKIP] new_nom vide id=#{id}"
        next
      end

      produit = Produit.find_by(id: id)

      unless produit
        skipped_count += 1
        puts "[SKIP] Produit introuvable id=#{id}"
        next
      end

      future_handle = new_nom.parameterize

      puts
      puts "--------------------------------------"
      puts "ID            : #{produit.id}"
      puts "OLD NOM CSV   : #{old_nom}"
      puts "OLD NOM DB    : #{produit.nom}"
      puts "NEW NOM       : #{new_nom}"
      puts "OLD HANDLE CSV: #{old_handle}"
      puts "OLD HANDLE DB : #{produit.handle}"
      puts "NEW HANDLE    : #{future_handle}"
      puts "STRIPE        : #{produit.stripe_product_id.presence || 'none'}"
      puts "--------------------------------------"

      if dry_run
        puts "[DRY-RUN] Aucun changement applique"
        next
      end

      begin
        old_db_nom = produit.nom
        old_db_handle = produit.handle

        produit.update!(nom: new_nom)

        if produit.stripe_product_id.present?
          Stripe::Product.update(
            produit.stripe_product_id,
            { name: produit.nom }
          )

          stripe_count += 1
          puts "[STRIPE] Produit synchronise"
        end

        updated_count += 1

        puts "[UPDATED]"
        puts "#{old_db_nom} -> #{produit.nom}"
        puts "#{old_db_handle} -> #{produit.handle}"
      rescue StandardError => e
        error_count += 1

        puts "[ERROR] id=#{id} #{e.class} - #{e.message}"
      end
    end

    puts
    puts "======================================"
    puts "TERMINE"
    puts "UPDATED : #{updated_count}"
    puts "STRIPE  : #{stripe_count}"
    puts "SKIPPED : #{skipped_count}"
    puts "ERRORS  : #{error_count}"
    puts "======================================"
    puts

    abort "Import termine avec erreurs" if error_count.positive?
  end
end