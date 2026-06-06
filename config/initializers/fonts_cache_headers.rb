# Cache longue durée uniquement pour les polices self-hostées dans public/fonts/.
# Les autres fichiers public/ (hero, robots.txt, etc.) gardent le comportement Rails par défaut.

class FontsCacheHeaders
  CACHE_CONTROL = "public, max-age=#{1.year.to_i}, immutable".freeze
  FONT_PATH = %r{\A/fonts/.+\.(?:woff2?|ttf|otf)\z}i

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    path = Rack::Request.new(env).path

    headers["Cache-Control"] = CACHE_CONTROL if path.match?(FONT_PATH)

    [status, headers, body]
  end
end

if Rails.env.production?
  Rails.application.config.middleware.insert_before ActionDispatch::Static, FontsCacheHeaders
end
