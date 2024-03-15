class Sousarticle < ApplicationRecord
  belongs_to :article
  belongs_to :produit

  scope :location_only, -> { joins(:article).where(articles: { locvente: 'location' }) }
  scope :vente_only, -> { joins(:article).where(articles: { locvente: 'vente' }) }
  
  # filtres analyses
  scope :filtredatedebut, -> (debut) { where("sousarticles.created_at >= ?", debut) }
  scope :filtredatefin, -> (fin) { where("sousarticles.created_at <= ?", fin) }
  
end