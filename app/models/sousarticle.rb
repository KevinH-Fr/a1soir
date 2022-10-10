class Sousarticle < ApplicationRecord
  belongs_to :article

  scope :article_courant, ->  (article_courant) { where("article_id = ?", article_courant)}

end
