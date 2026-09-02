# Pages d'erreur publiques. Hérite de Base : pas de panier / HTTP Basic boutique.
class ErrorsController < ActionController::Base
  skip_forgery_protection
  layout "error", only: :not_found

  def not_found
    I18n.locale = locale_from_original_path
    render status: :not_found
  end

  def unprocessable
    render file: Rails.public_path.join("422.html"), layout: false, status: :unprocessable_entity
  end

  def internal
    render file: Rails.public_path.join("500.html"), layout: false, status: :internal_server_error
  end

  private

  def locale_from_original_path
    path = request.env["action_dispatch.original_path"].presence || request.original_fullpath
    match = path.to_s.match(%r{\A/(fr|en)(?:/|\z|\?)})
    match ? match[1].to_sym : I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end
end
