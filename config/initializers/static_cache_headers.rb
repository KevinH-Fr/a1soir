# Cache longue durée pour les fichiers statiques servis depuis public/ et /assets.
# /fonts/* et /assets/* : immutable (noms versionnés ou fingerprintés).
# /images/mensurations_*.svg : revalidation ( Inkscape / itérations fréquentes ).
# /images/* : max-age 1 an sans immutable — renommer le fichier si le contenu change.

class StaticCacheHeaders
  ONE_YEAR = 1.year.to_i
  IMMUTABLE_CACHE = "public, max-age=#{ONE_YEAR}, immutable".freeze
  LONG_CACHE = "public, max-age=#{ONE_YEAR}".freeze
  REVALIDATE_CACHE = "public, max-age=0, must-revalidate".freeze

  ASSETS_PATH = %r{\A/assets/.+\z}i
  FONTS_PATH = %r{\A/fonts/.+\.(?:woff2?|ttf|otf)\z}i
  MENSURATION_SVG_PATH = %r{\A/images/mensurations_.+\.svg\z}i
  IMAGES_PATH = %r{\A/images/.+\z}i

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    path = Rack::Request.new(env).path

    headers["Cache-Control"] = cache_control_for(path) if cache_control_for(path)

    [status, headers, body]
  end

  private

  def cache_control_for(path)
    return IMMUTABLE_CACHE if path.match?(ASSETS_PATH) || path.match?(FONTS_PATH)
    return REVALIDATE_CACHE if path.match?(MENSURATION_SVG_PATH)
    return LONG_CACHE if path.match?(IMAGES_PATH)

    nil
  end
end

if Rails.env.production?
  Rails.application.config.middleware.insert_before ActionDispatch::Static, StaticCacheHeaders
end
