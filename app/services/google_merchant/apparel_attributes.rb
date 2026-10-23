# frozen_string_literal: true

module GoogleMerchant
  # Maps produit categories (and description for chaussures) to Google Merchant
  # gender and age_group values.
  class ApparelAttributes
    # Full category names only (%w splits on spaces: "accessoires femmes" → two tokens).
    FEMALE_CATEGORIES = [
      "accessoires femmes",
      "ensembles pantalons",
      "robes courtes",
      "robes longues",
      "robes de mariée courtes",
      "robes de mariée longues"
    ].freeze

    MALE_CATEGORIES = [
      "accessoires",
      "costume",
      "enfants"
    ].freeze

    KIDS_CATEGORY = "enfants"
    CHAUSSURES_CATEGORY = "chaussures"

    # Google product taxonomy IDs, most specific first: a smoking also tagged
    # "costume" must resolve to Tuxedos.
    GOOGLE_PRODUCT_CATEGORIES = [
      [["robes de mariée courtes", "robes de mariée longues"], 5329], # Wedding Dresses
      [["smokings"], 1580],                                           # Suits > Tuxedos
      [["combinaisons"], 5250],                                       # Jumpsuits & Rompers
      [["ensembles pantalons"], 7313],                                # Outfit Sets
      [["robes courtes", "robes longues"], 2271],                     # Dresses
      [["costume", "enfants"], 1594],                                 # Suits
      [["chaussures"], 187],                                          # Shoes
      [["accessoires", "accessoires femmes"], 167]                    # Clothing Accessories
    ].freeze

    class << self
      def google_product_category_for(produit)
        names = category_names(produit)
        GOOGLE_PRODUCT_CATEGORIES.find { |categories, _id| (names & categories).any? }&.last
      end

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
