# frozen_string_literal: true

# =============================================================================
# Copie des médias Cloudinary vers un AUTRE compte (changement de login).
#
# Ce n'est PAS une migration ActiveRecord (db/migrate). Rien n'est modifié
# en base : Active Storage garde les mêmes `blobs.key`, qui sont les
# `public_id` Cloudinary. On re-uploade chaque fichier sur le nouveau cloud
# AVEC LE MEME NOM. Ensuite seulement on pointera l'app vers le nouveau compte.
#
# -----------------------------------------------------------------------------
# Deux comptes, deux jeux de variables
# -----------------------------------------------------------------------------
#
# Aujourd'hui l'app est branchée sur l'ANCIEN compte via :
#   CLOUDINARY_KEY / CLOUDINARY_SECRET
#   (cloud_name encore hardcodé `dukne3lhz` dans config/initializers/cloudinary.rb)
#
# Ces variables NE DOIVENT PAS changer tant que la copie n'est pas finie :
#   prod, staging et ton .env local continuent de LIRE l'ancien compte.
#
# Le NOUVEAU compte (autre login Cloudinary) se passe UNIQUEMENT via des
# variables séparées, jamais commitées :
#   CLOUDINARY_DEST_CLOUD_NAME
#   CLOUDINARY_DEST_KEY
#   CLOUDINARY_DEST_SECRET
#
# Le script LIT avec les identifiants source (compte actuel) et ECRIT avec
# les identifiants dest. Rails / Active Storage / le site ne basculent pas.
#
# -----------------------------------------------------------------------------
# Git / environnements (la partie "intelligente")
# -----------------------------------------------------------------------------
#
# 1. Git
#    - Committer CE fichier (le mode d'emploi), sur une branche dédiée
#      (ex. `chore/cloudinary-new-account`).
#    - Ne JAMAIS committer .env, clés, allowlist complète de prod, dumps.
#    - Ne pas fusionner un switch de `CLOUDINARY_*` (les vrais logins app)
#      dans la même PR que la copie : d'abord copier, ensuite changer le
#      pointeur (cloud_name en ENV + deploy).
#
# 2. Local
#    - Garder CLOUDINARY_KEY/SECRET = ancien compte (comme aujourd'hui).
#    - Ajouter les 3 CLOUDINARY_DEST_* dans `.env` (gitignore).
#    - Tester avec 1 média : ONLY=faq1_fp6utw DRY_RUN=1 puis sans DRY_RUN.
#
# 3. Staging (recommandé avant la prod)
#    - La copie se fait depuis TON laptop (les DEST_* n'ont pas besoin
#      d'exister sur Heroku prod).
#    - Pour valider l'affichage : app Heroku staging (ou review app) avec
#      les NOUVELLES clés comme CLOUDINARY_* UNE FOIS qu'un lot est copié.
#    - La prod reste sur l'ancien compte pendant ce temps = rollback trivial.
#    - Alternative sans 2e app : preview en local, `.env` temporairement
#      basculé sur le dest APRÈS une copie test — puis remettre l'ancien
#      avant de reprendre le travail quotidien.
#
# 4. Prod
#    - Exporter la liste des blobs prod (c'est elle le catalogue réel) :
#        heroku run rake cloudinary:list_assets -a a1soir-2
#      (ou coller la sortie dans tmp/cloudinary_allowlist.txt en local)
#    - Lancer la copie EN LOCAL avec cette allowlist + DEST_* dans `.env`.
#    - Quand tout est copié : déployer le code (cloud_name via ENV), PUIS
#        heroku config:set CLOUDINARY_CLOUD_NAME=... \
#          CLOUDINARY_KEY=... CLOUDINARY_SECRET=... -a a1soir-2
#    - Rollback : remettre les anciennes vars Heroku. Garder l'ancien
#      compte quelques semaines.
#
# 5. Ne pas mettre CLOUDINARY_DEST_* en config Heroku prod "pour plus tard" :
#    un restart ou un oubli pourrait faire uploader les nouveaux fichiers
#    au mauvais endroit. Dest = local (ou un one-off `heroku config:set`
#    le jour J, puis unset).
#
# -----------------------------------------------------------------------------
# Commandes
# -----------------------------------------------------------------------------
#
#   # Voir ce qui serait copié (aucune écriture)
#   bin/rails cloudinary:list_assets
#   bin/rails cloudinary:copy_assets DRY_RUN=1
#
#   # Copier UN média (smoke test vers le nouveau compte)
#   bin/rails cloudinary:copy_assets ONLY=faq1_fp6utw
#
#   # Copier tout (blobs DB locale + IDs hardcodés dans app/)
#   bin/rails cloudinary:copy_assets
#
#   # Copier une liste exportée de la prod
#   bin/rails cloudinary:copy_assets ALLOWLIST=tmp/cloudinary_allowlist.txt
#
#   # Relancer sans réécrire ce qui existe déjà sur le dest (défaut)
#   # Forcer l'écrasement : OVERWRITE=1
#
# =============================================================================

require "open-uri"
require "tempfile"

module CloudinaryCopy
  SOURCE_CLOUD_FALLBACK = "dukne3lhz"
  ALLOWLIST_PATH = Rails.root.join("tmp/cloudinary_allowlist.txt")
  REPORT_PATH = Rails.root.join("tmp/cloudinary_copy_report.txt")

  module_function

  def source_creds
    {
      cloud_name: ENV["CLOUDINARY_CLOUD_NAME"].presence || SOURCE_CLOUD_FALLBACK,
      api_key: ENV.fetch("CLOUDINARY_KEY"),
      api_secret: ENV.fetch("CLOUDINARY_SECRET")
    }
  end

  def dest_creds
    {
      cloud_name: ENV.fetch("CLOUDINARY_DEST_CLOUD_NAME"),
      api_key: ENV.fetch("CLOUDINARY_DEST_KEY"),
      api_secret: ENV.fetch("CLOUDINARY_DEST_SECRET")
    }
  end

  def dry_run?
    ENV["DRY_RUN"].present? && ENV["DRY_RUN"] != "0"
  end

  def overwrite?
    ENV["OVERWRITE"] == "1"
  end

  def pause
    sleep(ENV.fetch("SLEEP", "0.35").to_f)
  end

  # --- Collecte des public_id (allowlist A1soir uniquement) -----------------

  def collect_public_ids
    if ENV["ONLY"].present?
      return ENV["ONLY"].split(",").map { |id| normalize_id(id) }.uniq
    end

    if ENV["ALLOWLIST"].present?
      path = Rails.root.join(ENV["ALLOWLIST"])
      return File.readlines(path, chomp: true).map { |id| normalize_id(id) }.reject(&:blank?).uniq
    end

    ids = []
    include_list = ENV.fetch("INCLUDE", "blobs,static").split(",").map(&:strip)

    ids.concat(blob_public_ids) if include_list.include?("blobs")
    ids.concat(static_public_ids) if include_list.include?("static")

    ids = ids.reject(&:blank?).uniq.sort
    limit = ENV["LIMIT"].to_i
    limit.positive? ? ids.first(limit) : ids
  end

  def blob_public_ids
    ActiveStorage::Blob.distinct.pluck(:key).map { |key| normalize_id(key) }
  end

  # Images / vidéos des pages, hardcodées dans app/ (pas dans Active Storage).
  def static_public_ids
    ids = []
    Dir.glob(Rails.root.join("app/**/*.{rb,erb}")).each do |path|
      text = File.read(path)
      text.scan(%r{res\.cloudinary\.com/[^/"'\s]+/(?:image|video)/upload/[^"'\s)]+}) do |url|
        ids << public_id_from_url(url)
      end
      text.scan(/cloudinary_static_image_url\(\s*"([^"]+)"/) { ids << normalize_id(Regexp.last_match(1)) }
      text.scan(/cloudinary_video_url\(\s*"([^"]+)"/) { ids << normalize_id(Regexp.last_match(1)) }
      text.scan(/cloudinary_image\(\s*\n?\s*"([^"]+)"/) { ids << normalize_id(Regexp.last_match(1)) }
    end
    ids.concat(%w[no_photo_black_p8wyfh])
    ids.compact.uniq.sort
  end

  def public_id_from_url(url)
    path = url.to_s.split("?").first
    after_upload = path.split("/upload/", 2).last
    return if after_upload.blank?

    parts = after_upload.split("/")
    while parts.any? && (parts.first.include?(",") || parts.first.match?(/\Av\d+\z/))
      parts.shift
    end
    normalize_id(parts.join("/"))
  end

  def normalize_id(id)
    id.to_s.strip.sub(/\A\/*/, "").sub(/\.(mp4|mov|webm|m4v)\z/i, "")
  end

  # --- API Cloudinary -------------------------------------------------------

  def find_on(creds, public_id)
    candidates = [public_id]
    without_ext = public_id.sub(/\.(png|jpe?g|webp|gif)\z/i, "")
    candidates << without_ext if without_ext != public_id

    %w[image video].each do |resource_type|
      %w[authenticated upload].each do |type|
        candidates.each do |pid|
          begin
            resource = Cloudinary::Api.resource(
              pid,
              creds.merge(resource_type: resource_type, type: type)
            )
            return resource.merge("_lookup_public_id" => pid)
          rescue Cloudinary::Api::NotFound
            next
          end
        end
      end
    end
    nil
  end

  def signed_download_url(resource)
    pid = resource["_lookup_public_id"] || resource["public_id"]
    Cloudinary::Utils.private_download_url(
      pid,
      resource["format"],
      source_creds.merge(
        resource_type: resource["resource_type"],
        type: resource["type"],
        attachment: false
      )
    )
  end

  def copy_one!(public_id)
    tempfile = nil
    source = find_on(source_creds, public_id)
    pause
    return { status: :missing_source, public_id: public_id } if source.nil?

    real_id = source["_lookup_public_id"] || source["public_id"]

    if !overwrite? && find_on(dest_creds, real_id)
      pause
      return { status: :skipped_exists, public_id: real_id }
    end
    pause

    if dry_run?
      return {
        status: :dry_run,
        public_id: real_id,
        resource_type: source["resource_type"],
        type: source["type"]
      }
    end

    url = source["secure_url"].presence || signed_download_url(source)
    tempfile = Tempfile.new(["cloudinary-copy-", ".#{source['format']}"], binmode: true)
    URI.open(url) { |io| IO.copy_stream(io, tempfile) }
    tempfile.rewind

    Cloudinary::Uploader.upload(
      tempfile.path,
      dest_creds.merge(
        public_id: real_id,
        resource_type: source["resource_type"],
        type: source["type"],
        overwrite: true
      )
    )
    pause

    { status: :copied, public_id: real_id, resource_type: source["resource_type"], type: source["type"] }
  ensure
    tempfile&.close!
  end

  def write_allowlist!(ids)
    File.write(ALLOWLIST_PATH, "#{ids.join("\n")}\n")
  end

  def write_report!(rows)
    File.write(REPORT_PATH, rows.map { |row| row.values.join("\t") }.join("\n") + "\n")
  end
end

namespace :cloudinary do
  desc "Liste les public_id A1soir (blobs DB + pages) sans copier"
  task list_assets: :environment do
    ids = CloudinaryCopy.collect_public_ids
    CloudinaryCopy.write_allowlist!(ids)
    puts "Source cloud : #{CloudinaryCopy.source_creds[:cloud_name]}"
    puts "Médias listés : #{ids.size}"
    puts "Fichier       : #{CloudinaryCopy::ALLOWLIST_PATH}"
    puts "(tmp/ est gitignoré — ne pas committer une allowlist prod)"
    puts
    ids.each { |id| puts id }
  end

  desc "Copie les médias de l'ancien compte (CLOUDINARY_*) vers CLOUDINARY_DEST_*"
  task copy_assets: :environment do
    ids = CloudinaryCopy.collect_public_ids
    abort "Aucun public_id à copier." if ids.empty?

    dest = CloudinaryCopy.dest_creds
    puts "Source : #{CloudinaryCopy.source_creds[:cloud_name]}  (CLOUDINARY_KEY actuel)"
    puts "Dest   : #{dest[:cloud_name]}  (CLOUDINARY_DEST_*)"
    puts "Mode   : #{CloudinaryCopy.dry_run? ? 'DRY_RUN (aucune écriture dest)' : 'écriture réelle'}"
    puts "Overwrite dest si déjà présent : #{CloudinaryCopy.overwrite?}"
    puts "À traiter : #{ids.size}"
    puts

    rows = []
    ids.each_with_index do |public_id, index|
      print "[#{index + 1}/#{ids.size}] #{public_id} … "
      result = CloudinaryCopy.copy_one!(public_id)
      puts result[:status]
      rows << result
    rescue StandardError => e
      puts "ERROR #{e.class}: #{e.message}"
      rows << { status: :error, public_id: public_id, message: e.message }
    end

    CloudinaryCopy.write_report!(rows)
    summary = rows.group_by { |row| row[:status] }.transform_values(&:size)
    puts
    puts "Résumé : #{summary.inspect}"
    puts "Rapport : #{CloudinaryCopy::REPORT_PATH}"
  end
end
