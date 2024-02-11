class Produit < ApplicationRecord
  belongs_to :categorie_produit, optional: true
  belongs_to :fournisseur, optional: true

  def full_name
    nom
  end
end
