# frozen_string_literal: true

module PublicSeoHelper
  def public_page_path_params
    request.path_parameters.symbolize_keys.except(:locale)
  end

  def public_page_url(locale: I18n.locale)
    url_for(public_page_path_params.merge(locale: locale, only_path: false))
  end

  # Absolute URL for files under public/ (no ?locale= query — unlike root_url).
  def public_static_asset_url(path)
    normalized = path.to_s.start_with?("/") ? path : "/#{path}"
    "#{request.base_url}#{normalized}"
  end

  def structured_home_url(locale: I18n.locale)
    home_url(locale: locale)
  end

  def structured_site_url(locale: I18n.locale)
    localized_root_url(locale: locale)
  end

  def structured_store_logo_url
    public_static_asset_url("images/autourdunsoir_drapeau.png")
  end
end
