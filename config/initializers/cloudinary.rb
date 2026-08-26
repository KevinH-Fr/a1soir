# frozen_string_literal: true

# Deux jeux de credentials, un seul interrupteur pour l'app.
#
#   CLOUDINARY_*              ancien compte (source de la copie) — restera
#                             le jeu "principal" une fois la migration finie
#   CLOUDINARY_DEST_*         nouveau compte (cible de la copie)
#   CLOUDINARY_USE=source|dest  ce que Rails / Active Storage / les helpers
#                             utilisent. Défaut : source.
#
# Le script `cloudinary:copy_assets` ignore CLOUDINARY_USE : il lit toujours
# source et écrit toujours dest. Tu peux donc tester l'app sur dest tout en
# relançant une copie.
#
# Le jour J : recopier DEST_* vers CLOUDINARY_*, supprimer DEST_*,
# CLOUDINARY_USE=source (ou supprimer la var).
module CloudinaryEnv
  LEGACY_CLOUD_NAME = "dukne3lhz"

  module_function

  def use_dest?
    ENV["CLOUDINARY_USE"].to_s.strip.downcase == "dest"
  end

  def source
    {
      cloud_name: ENV["CLOUDINARY_CLOUD_NAME"].presence || LEGACY_CLOUD_NAME,
      api_key: ENV["CLOUDINARY_KEY"],
      api_secret: ENV["CLOUDINARY_SECRET"]
    }
  end

  def dest
    {
      cloud_name: ENV["CLOUDINARY_DEST_CLOUD_NAME"],
      api_key: ENV["CLOUDINARY_DEST_KEY"],
      api_secret: ENV["CLOUDINARY_DEST_SECRET"]
    }
  end

  def app
    use_dest? ? dest : source
  end

  def dest_folder
    ENV["CLOUDINARY_DEST_FOLDER"].presence
  end

  def source_folder
    ENV["CLOUDINARY_SOURCE_FOLDER"].presence
  end
end

Cloudinary.config do |config|
  creds = CloudinaryEnv.app
  config.cloud_name = creds[:cloud_name]
  config.api_key = creds[:api_key]
  config.api_secret = creds[:api_secret]
  config.secure = true
  config.sign_url = true
  config.type = "authenticated"
  config.cdn_subdomain = true
  config.cors_origin = ["https://a1soir-2-2a03802389d6.herokuapp.com", "localhost:3000"]
end
