# frozen_string_literal: true

module Public
  class SeoPagesController < Public::ApplicationController
    helper_method :seo_meta_key

    def hub
      @pages_by_group = SeoPages::Registry.grouped_for_hub
      @seo_meta_key = :seo_guides_hub
    end

    def show
      load_page
      load_boutique_context
      @produits = SeoPages::ProductScope.call(@page)
      @related_pages = SeoPages::Registry.related_pages(@page)
      render @page[:type]
    end

    def seo_meta_key
      @seo_meta_key
    end

    private

    def load_page
      scope = params[:scope].presence || (request.path.include?("/guides/") ? "guides" : "local")
      @page = SeoPages::Registry.find(params[:slug], scope: scope)
      raise ActiveRecord::RecordNotFound unless @page

      @seo_meta_key = @page[:meta_key]
    end

    def load_boutique_context
      includes = Array(@page[:includes])
      return if includes.blank?

      texte = current_texte
      if texte.present? && includes.intersect?(%w[boutique_snippet map rdv])
        @texteContact  = texte.contact
        @texteHoraire  = texte.mode_periode_speciale? ? texte.horaire_periode_speciale : texte.horaire
        @texteBoutique = texte.boutique
        @texteAdresse  = texte.adresse
      end

      @google_data = GooglePlacesService.fetch if includes.include?("reviews")
    end
  end
end
