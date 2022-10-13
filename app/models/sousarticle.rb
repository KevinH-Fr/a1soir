class Sousarticle < ApplicationRecord
  belongs_to :article

  enum natures: ["retouches", "ceinture", "chaussures", 
                "nœud papillon", "veste", "pantalon", 
                "chemise", "pochette", "boutons de manchette",
                "gilet", "autre"]

  scope :article_courant, ->  (article_courant) { where("article_id = ?", article_courant)}
  scope :sum_sousarticles, -> {sum('prix_sousarticle')}
  scope :compte_sousarticles, -> {count('nature')}

end
