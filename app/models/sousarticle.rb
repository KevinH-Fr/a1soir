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
  before_create :capture_promotion_info

  after_commit :update_produit_availability, on: [:create, :update, :destroy]
  
  private

  def capture_promotion_info
    return unless produit&.en_promotion?
    note = "Promotion appliquée (ancien prix : #{produit.ancien_prixvente} €)"
    self.commentaires = [note, commentaires.presence].compact.join(" | ")
  end

  # Met à jour la disponibilité du produit concerné
  # Appelé après chaque création, modification ou suppression d'un sousarticle
  def update_produit_availability
    p = produit
    return if p.nil? || p.destroyed?

    p.update_today_availability
  end
  
end