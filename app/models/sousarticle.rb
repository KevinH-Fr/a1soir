class Sousarticle < ApplicationRecord
  belongs_to :article
  belongs_to :produit

  scope :service_only, -> { joins(:produit).where(produits: { categorie_produit_id: CategorieProduit.where(service: true) }) }

  scope :location_only, -> { joins(:article).where(articles: { locvente: 'location' }) }
  scope :vente_only, -> { joins(:article).where(articles: { locvente: 'vente' }) }
  
  # filtres analyses
  scope :filtredatedebut, -> (debut) { where("sousarticles.created_at >= ?", debut) }
  scope :filtredatefin, -> (fin) { where("sousarticles.created_at <= ?", fin) }
  
  # Callback pour mettre à jour la disponibilité du produit concerné
  # Se déclenche après chaque création, modification ou suppression d'un sousarticle
  # car cela affecte directement la disponibilité du produit (location)
  after_commit :update_produit_availability, on: [:create, :update, :destroy]
  
  private
  
  # Met à jour la disponibilité du produit concerné
  # Appelé après chaque création, modification ou suppression d'un sousarticle
  def update_produit_availability
    # Mettre à jour la disponibilité du produit à la date du jour
    produit&.update_today_availability
  end
  
end