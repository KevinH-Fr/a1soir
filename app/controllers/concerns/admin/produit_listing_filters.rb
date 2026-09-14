# frozen_string_literal: true

# Filtres catalogue partagés (taille, couleur, catégorie, type) : listing produits et dashboard Analyses.
module Admin
  module ProduitListingFilters
    extend ActiveSupport::Concern

    ADMIN_PRODUIT_FILTER_KEYS = %i[
      filter_taille filter_couleur filter_categorie filter_type_produit
    ].freeze

    def apply_taille_filter(scope, value)
      return scope unless value.present?

      if value == "na"
        scope.where(taille_id: nil)
      else
        scope.by_taille(value)
      end
    end

    def apply_couleur_filter(scope, value)
      return scope unless value.present?

      if value == "na"
        scope.where(couleur_id: nil)
      else
        scope.by_couleur(value)
      end
    end

    def apply_categorie_filter(scope, value)
      return scope unless value.present?

      if value == "na"
        scope.left_outer_joins(:categorie_produits).where(categorie_produits: { id: nil })
      else
        scope.by_categorie(CategorieProduit.find(value))
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
      return scope unless value.present?

      if value == "na"
        scope.where(type_produit_id: nil)
      else
        scope.where(type_produit_id: value)
      end
    end

    def apply_fournisseur_filter(scope, value)
      return scope unless value.present?

      if value == "na"
        scope.where(fournisseur_id: nil)
      else
        scope.by_fournisseur(Fournisseur.find(value))
      end
    end

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
      scope
    end

    def product_dimension_filtered?(filter_params)
      ADMIN_PRODUIT_FILTER_KEYS.any? { |key| filter_params[key].present? } ||
        filter_params[:filter_locvente].present?
    end
  end
end
