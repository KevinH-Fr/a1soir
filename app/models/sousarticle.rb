class Sousarticle < ApplicationRecord
  belongs_to :article

  enum natures: ["Chemise", "Ceinture", "Pantalon"]

  scope :article_courant, ->  (article_courant) { where("article_id = ?", article_courant)}
  scope :sum_sousarticles, -> {sum('prix')}
  scope :compte_sousarticles, -> {count('nature')}

end
