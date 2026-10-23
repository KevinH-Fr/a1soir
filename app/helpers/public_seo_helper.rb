# frozen_string_literal: true

module PublicSeoHelper
  def public_page_path_params
    request.path_parameters.symbolize_keys.except(:locale)
  end

  def public_page_url(locale: I18n.locale)
    seo_show_page_url(locale) || url_for(public_page_path_params.merge(locale: locale, only_path: false))
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
    public_static_asset_url("images/logo_Autour_d_un_soir.png")
  end

  def default_og_image_url
    public_static_asset_url("images/autour_d_un_soir_og.png")
  end

  private

  # guides/:slug et :slug partagent seo_pages#show. url_for prend la première
  # route et canonise à tort les landings locales vers /guides/:slug, qui 301.
  def seo_show_page_url(locale)
    return unless controller.controller_path == "public/seo_pages" && controller.action_name == "show"

    page = instance_variable_get(:@page)
    return unless page.is_a?(Hash)

    slug = page[:slug].presence
    scope = page[:scope].to_s
    return if slug.blank? || scope.blank?

    options = { slug: slug, locale: locale, only_path: false }
    scope == "guides" ? seo_guide_url(options) : seo_page_url(options)
  end
end
