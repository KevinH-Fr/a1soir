# frozen_string_literal: true

# Filtres catalogue partagés (taille, couleur, catégorie, type) : listing produits et dashboard Analyses.
module Admin
  module ProduitListingFilters
    extend ActiveSupport::Concern

    ADMIN_PRODUIT_FILTER_KEYS = %i[
      filter_taille filter_couleur filter_categorie filter_type_produit filter_fournisseur
    ].freeze

    # « Tous » est explicite : l'absence de paramètre reste le catalogue mariage.
    CATALOGUE_FILTER_ALL = "tous"

    # Un choix par groupe (publication, eshop, dispo). Les groupes se cumulent.
    STATUT_FILTER_OPTIONS = [
      { value: "actif", label: "actif", group: :publication },
      { value: "archive", label: "archivé", group: :publication },
      { value: "eshop", label: "eshop", group: :eshop },
      { value: "pas_eshop", label: "pas eshop", group: :eshop },
      { value: "dispo", label: "dispo", group: :dispo },
      { value: "pas_dispo", label: "pas dispo", group: :dispo }
    ].freeze

    STATUT_FILTER_ALIASES = { "true" => "actif", "false" => "archive" }.freeze

    # Filtres Analyses qui acceptent plusieurs ids (query `filter_categorie[]=…`).
    ANALYSES_MULTI_FILTER_KEYS = (ADMIN_PRODUIT_FILTER_KEYS + %i[filter_profile]).freeze

    def self.normalize_filter_values(value)
      Array.wrap(value).flatten.filter_map { |v| v.to_s.strip.presence }.uniq
    end

    def self.normalize_statut_filter_values(value)
      groups = STATUT_FILTER_OPTIONS.to_h { |option| [option[:value], option[:group]] }
      groups["na"] = :publication
      picked = {}

      normalize_filter_values(value).each do |raw|
        token = STATUT_FILTER_ALIASES[raw] || raw
        group = groups[token]
        next unless group

        picked[group] = token
      end

      picked.values
    end

    def self.statut_filter_label(value)
      token = STATUT_FILTER_ALIASES[value.to_s] || value.to_s
      return "sans statut" if token == "na"

      STATUT_FILTER_OPTIONS.find { |option| option[:value] == token }&.fetch(:label) || token
    end

    # Décoche la valeur, ou remplace l'autre choix du même groupe.
    def self.statut_filter_toggle_values(selected, value)
      current = normalize_statut_filter_values(selected)
      option = STATUT_FILTER_OPTIONS.find { |item| item[:value] == value }
      return current unless option

      without_group = current.reject do |token|
        STATUT_FILTER_OPTIONS.find { |item| item[:value] == token }&.fetch(:group) == option[:group]
      end
      current.include?(value) ? without_group : without_group + [value]
    end

    def apply_taille_filter(scope, value)
      apply_nullable_fk_filter(scope, :taille_id, value)
    end

    def apply_couleur_filter(scope, value)
      apply_nullable_fk_filter(scope, :couleur_id, value)
    end

    def apply_categorie_filter(scope, value)
      values = Admin::ProduitListingFilters.normalize_filter_values(value)
      return scope if values.empty?

      ids = values.reject { |v| v == "na" }
      include_na = values.include?("na")

      if include_na && ids.empty?
        scope.left_outer_joins(:categorie_produits).where(categorie_produits: { id: nil })
      elsif include_na
        scope.left_outer_joins(:categorie_produits)
             .where("categorie_produits.id IN (?) OR categorie_produits.id IS NULL", ids)
             .distinct
      else
        scope.by_categories(ids)
      end
    end

    def apply_catalogue_filter(scope, value)
      return scope if value.to_s == CATALOGUE_FILTER_ALL
      return scope unless Produit::CATALOGUES.include?(value.to_s)

      scope.where(catalogue: Produit.catalogue_values_for(value.to_s))
    end

    def apply_rubrique_filter(scope, value)
      ids = Admin::ProduitListingFilters.normalize_filter_values(value)
      return scope if ids.empty?

      scope.by_rubriques(ids)
    end

    def apply_statut_filter(scope, value)
      Admin::ProduitListingFilters.normalize_statut_filter_values(value).reduce(scope) do |filtered, token|
        case token
        when "actif"
          filtered.actif
        when "archive"
          filtered.inactif
        when "na"
          filtered.where(actif: nil)
        when "eshop"
          filtered.where(eshop: true)
        when "pas_eshop"
          filtered.where(eshop: [false, nil])
        when "dispo"
          filtered.where(today_availability: true)
        when "pas_dispo"
          filtered.where(today_availability: false)
        else
          filtered
        end
      end
    end

    def apply_type_produit_filter(scope, value)
      apply_nullable_fk_filter(scope, :type_produit_id, value)
    end

    def apply_fournisseur_filter(scope, value)
      apply_nullable_fk_filter(scope, :fournisseur_id, value)
    end

    def apply_nullable_fk_filter(scope, column, value)
      values = Admin::ProduitListingFilters.normalize_filter_values(value)
      return scope if values.empty?

      ids = values.reject { |v| v == "na" }
      include_na = values.include?("na")

      if include_na && ids.empty?
        scope.where(column => nil)
      elsif include_na
        scope.where(column => ids).or(scope.where(column => nil))
      else
        scope.where(column => ids)
      end
    end
    private :apply_nullable_fk_filter

    def apply_prix_filter(scope, value)
      return scope unless value.present?

      if value == "na"
        scope.where("(prixvente IS NULL OR prixvente <= 0) AND (prixlocation IS NULL OR prixlocation <= 0)")
      else
        scope.by_prixmax(value.to_f)
      end
    end

    def apply_produit_listing_filters(scope, filter_params)
      scope = apply_taille_filter(scope, filter_params[:filter_taille])
      scope = apply_couleur_filter(scope, filter_params[:filter_couleur])
      scope = apply_categorie_filter(scope, filter_params[:filter_categorie])
      scope = apply_type_produit_filter(scope, filter_params[:filter_type_produit])
      scope = apply_fournisseur_filter(scope, filter_params[:filter_fournisseur])
      scope
    end

    def product_dimension_filtered?(filter_params)
      ADMIN_PRODUIT_FILTER_KEYS.any? { |key| filter_params[key].present? } ||
        filter_params[:filter_locvente].present?
    end
  end
end
