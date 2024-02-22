class Article < ApplicationRecord
  belongs_to :produit
  belongs_to :commande

  scope :location_only, -> { where(locvente: 'location') }
  scope :vente_only, -> { where(locvente: 'vente') }

end
