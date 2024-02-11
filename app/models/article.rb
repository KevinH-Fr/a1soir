class Article < ApplicationRecord
  belongs_to :produit
  belongs_to :commande

end
