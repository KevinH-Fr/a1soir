class Sousarticle < ApplicationRecord
  belongs_to :article
  belongs_to :produit

  scope :service_only, -> { joins(:produit).where(produits: { categorie_produit_id: CategorieProduit.where(service: true) }) }

  scope :location_only, -> { joins(:article).where(articles: { locvente: 'location' }) }
  scope :vente_only, -> { joins(:article).where(articles: { locvente: 'vente' }) }
  
  # filtres analyses
  scope :filtredatedebut, -> (debut) { where("sousarticles.created_at >= ?", debut) }
  scope :filtredatefin, -> (fin) { where("sousarticles.created_at <= ?", fin) }
  
end