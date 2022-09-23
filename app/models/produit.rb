class Produit < ApplicationRecord
    has_one_attached :image1

    enum categories: ["Robes de soirées", "Robes de mariées", "Costumes hommes", "Accessoires", "Costumes et déguisements"]

    scope :categorie_robes_soirees, -> { where("categorie = ?", "Robes de soirées") } # categorie 1
    scope :categorie_robes_mariees, -> { where("categorie = ?", "Robes de mariées") }
    scope :categorie_costumes_hommes, -> { where("categorie = ?", "Costumes hommes") }
    scope :categorie_accessoires, -> { where("categorie = ?", "Accessoires") }
    scope :categorie_costumes_deguisements, -> { where("categorie = ?", "Costumes et déguisements") }
end
