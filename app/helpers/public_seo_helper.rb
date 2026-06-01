# frozen_string_literal: true

module PublicSeoHelper
  def public_page_path_params
    request.path_parameters.symbolize_keys.except(:locale)
  end

  def public_page_url(locale: I18n.locale)
    url_for(public_page_path_params.merge(locale: locale, only_path: false))
  end
end
