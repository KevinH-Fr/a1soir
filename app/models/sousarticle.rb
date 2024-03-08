class Sousarticle < ApplicationRecord
  belongs_to :article
  belongs_to :produit

  scope :location_only, -> { joins(:article).where(articles: { locvente: 'location' }) }
  scope :vente_only, -> { joins(:article).where(articles: { locvente: 'vente' }) }
  
end