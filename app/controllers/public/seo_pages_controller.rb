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
      return if performed?

      load_boutique_context
      load_seo_page_assets
      @related_pages = SeoPages::Registry.related_pages(@page)
      render @page[:type]
    end

    def seo_meta_key
      @seo_meta_key
    end

    private

    def load_page
      scope = params[:scope].presence || (request.path.include?("/guides/") ? "guides" : "local")
      slug = params[:slug].to_s
      @page = SeoPages::Registry.find(slug, scope: scope)

      unless @page
        alternate_scope = scope == "guides" ? "local" : "guides"
        alternate = SeoPages::Registry.find(slug, scope: alternate_scope)
        if alternate
          redirect_to canonical_seo_page_path(alternate), status: :moved_permanently
          return
        end
        raise ActiveRecord::RecordNotFound
      end

      @seo_meta_key = @page[:meta_key]
    end

    def canonical_seo_page_path(page)
      if page[:scope] == "guides"
        seo_guide_path(slug: page[:slug])
      else
        seo_page_path(slug: page[:slug])
      end
    end

    def load_seo_page_assets
      section_keys = I18n.t(
        "public.seo_pages.#{SeoPages::Registry.i18n_key(@page)}.sections",
        default: {}
      ).keys.map(&:to_s)

      @seo_section_images = SeoPages::CategoryImages.call(@page, section_keys: section_keys)
      used_product_ids = @seo_section_images.values.filter_map { |section| section[:product_id] }
      @produits = SeoPages::ProductScope.call(@page, exclude_product_ids: used_product_ids)
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
