class Produit < ApplicationRecord
  belongs_to :categorie_produit, optional: true
  belongs_to :fournisseur, optional: true

  has_one_attached :image1
  has_many_attached :images

  def full_name
    nom
  end
end
