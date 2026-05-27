# frozen_string_literal: true

require "csv"

namespace :products do
  def seo_ai_csv_path(arg_path)
    csv_path = arg_path.presence || ProductsSeoAi::Config.export_csv
    path = Pathname.new(csv_path)
    path = Rails.root.join(path) unless path.absolute?
    path
  end

  desc "Prepare SEO AI families JSON from export CSV (group by handle). Dev default: tmp/produits_seo_export.csv"
  task :seo_ai_prepare, [:csv_path] => :environment do |_t, args|
    path = seo_ai_csv_path(args[:csv_path])
    abort "CSV introuvable : #{path}" unless path.exist?

    result = ProductsSeoAi::Prepare.call(csv_path: path)

    puts
    puts "Préparation terminée (#{Rails.env})"
    puts "  Familles : #{result[:family_count]}"
    puts "  SKUs     : #{result[:sku_count]}"
    puts "  Fichier  : #{result[:families_path]}"
    puts
  end

  desc "Generate SEO titles via OpenAI (batched by handle). BATCH_SIZE, BATCH_FROM, LIMIT, FORCE, SEO_AI_MODEL"
  task seo_ai_generate: :environment do
    unless ENV["OPENAI_API_KEY"].present?
      abort "OPENAI_API_KEY manquante. Définis-la dans .env pour la génération locale."
    end

    ProductsSeoAi::Generate.call
  end

  desc "Build import CSV from AI batch results + families JSON. Dev default: tmp/produits_seo_import.csv"
  task seo_ai_build_import: :environment do
    result = ProductsSeoAi::BuildImport.call

    puts
    puts "CSV import généré (#{Rails.env})"
    puts "  Fichier : #{result[:output_path]}"
    puts "  Lignes  : #{result[:row_count]}"

    if result[:missing_handles].any?
      puts
      puts "  ATTENTION : #{result[:missing_handles].size} handles sans résultat IA"
      puts "  #{result[:missing_handles].first(10).join(', ')}#{'...' if result[:missing_handles].size > 10}"
    end

    puts
  end

  desc "Validate SEO import CSV (errors + warnings report)"
  task :seo_ai_validate, [:csv_path] => :environment do |_t, args|
    csv_path = args[:csv_path].presence || ProductsSeoAi::Config.import_csv

    result = ProductsSeoAi::Validate.call(csv_path: csv_path)

    abort "Validation échouée : #{result[:errors].size} erreur(s)" if result[:errors].any?
  end

  desc "Dev: export + prepare + generate (LIMIT=5) + build + validate + import dry-run"
  task seo_ai_dev_sample: :environment do
    unless Rails.env.development?
      abort "Cette tâche est réservée à l'environnement development."
    end

    unless ENV["OPENAI_API_KEY"].present?
      abort "OPENAI_API_KEY manquante dans .env"
    end

    export_path = Rails.root.join("tmp", "produits_seo_export.csv")
    import_path = Rails.root.join("tmp", "produits_seo_import.csv")

    puts "=== 1/6 Export DB locale ==="
    Rake::Task["products:seo_export"].invoke
    Rake::Task["products:seo_export"].reenable

    puts "=== 2/6 Prepare familles ==="
    ProductsSeoAi::Prepare.call(csv_path: export_path)

    puts "=== 3/6 Génération IA (échantillon LIMIT=#{ENV.fetch('LIMIT', '5')}) ==="
    ProductsSeoAi::Generate.call(limit: ENV.fetch("LIMIT", "5").to_i)

    puts "=== 4/6 Build CSV import ==="
    ProductsSeoAi::BuildImport.call(output_path: import_path)

    puts "=== 5/6 Validation ==="
    ProductsSeoAi::Validate.call(csv_path: import_path)

    puts "=== 6/6 Import dry-run ==="
    ENV["DRY_RUN"] = "true"
    csv_content = File.read(import_path)
    rows = CSV.parse(csv_content, headers: true)
    approved = rows.count { |r| r["approved"].to_s.strip.downcase == "yes" }
    puts "Lignes importables (approved=yes) : #{approved}/#{rows.size}"
    puts
    puts "Pour appliquer en dev :"
    puts "  DRY_RUN=false bin/rails products:seo_import[tmp/produits_seo_import.csv]"
    puts
    puts "Pour regénérer tout le catalogue dev :"
    puts "  bin/rails products:seo_export"
    puts "  bin/rails products:seo_ai_prepare"
    puts "  bin/rails products:seo_ai_generate"
    puts "  bin/rails products:seo_ai_build_import"
    puts
  end
end
