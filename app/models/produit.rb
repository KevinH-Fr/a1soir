class Produit < ApplicationRecord
  belongs_to :categorie_produit, optional: true
  belongs_to :fournisseur, optional: true
end
