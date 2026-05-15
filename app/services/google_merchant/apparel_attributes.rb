# frozen_string_literal: true

module GoogleMerchant
  # Maps produit categories (and description for chaussures) to Google Merchant
  # gender and age_group values.
  class ApparelAttributes
    FEMALE_CATEGORIES = %w[
      accessoires femmes
      ensembles pantalons
      robes courtes
      robes longues
      robes de mariée courtes
      robes de mariée longues
    ].freeze

    MALE_CATEGORIES = %w[
      accessoires
      costume
      enfants
    ].freeze

    KIDS_CATEGORY = "enfants"
    CHAUSSURES_CATEGORY = "chaussures"

    class << self
      def age_group_for(produit)
        category_names(produit).include?(KIDS_CATEGORY) ? "kids" : "adult"
      end

      def gender_for(produit)
        names = category_names(produit)
        return gender_for_chaussures(produit) if names.include?(CHAUSSURES_CATEGORY)
        return "female" if (names & FEMALE_CATEGORIES).any?
        return "male" if (names & MALE_CATEGORIES).any?

        "unisex"
      end

      def category_names(produit)
        produit.categorie_produits.map { |c| c.nom.to_s.downcase.strip }
      end

      private

      def gender_for_chaussures(produit)
        plain = ActionController::Base.helpers.strip_tags(produit.description.to_s).downcase
        plain.match?(/\bhomme\b/) ? "male" : "female"
      end
    end
  end
end
