# frozen_string_literal: true

# Filtres catalogue partagés (taille, couleur, catégorie, type) : listing produits et dashboard Analyses.
module Admin
  module ProduitListingFilters
    extend ActiveSupport::Concern

    ADMIN_PRODUIT_FILTER_KEYS = %i[
      filter_taille filter_couleur filter_categorie filter_type_produit filter_fournisseur
    ].freeze

    # Filtres Analyses qui acceptent plusieurs ids (query `filter_categorie[]=…`).
    ANALYSES_MULTI_FILTER_KEYS = (ADMIN_PRODUIT_FILTER_KEYS + %i[filter_profile]).freeze

    def self.normalize_filter_values(value)
      Array.wrap(value).flatten.filter_map { |v| v.to_s.strip.presence }.uniq
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

    def apply_statut_filter(scope, value)
      return scope unless value.present?

      case value
      when "na"
        scope.where(actif: nil)
      when "true"
        scope.actif
      when "false"
        scope.inactif
      else
        scope
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
