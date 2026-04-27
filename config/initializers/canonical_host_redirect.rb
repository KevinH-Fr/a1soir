class CanonicalHostRedirect
  CANONICAL_HOST = "a1soir.com"
  REDIRECTED_HOSTS = ["www.a1soir.com"].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    if REDIRECTED_HOSTS.include?(request.host)
      return [
        301,
        {
          "Location" => "https://#{CANONICAL_HOST}#{request.fullpath}",
          "Content-Type" => "text/html; charset=utf-8",
          "Cache-Control" => "no-cache"
        },
        []
      ]
    end

    @app.call(env)
  end
end

Rails.application.config.middleware.insert_before(0, CanonicalHostRedirect)
