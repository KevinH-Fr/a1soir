class Produit < ApplicationRecord
  belongs_to :categorie_produit
  belongs_to :fournisseur
end
