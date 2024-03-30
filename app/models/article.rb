class Article < ApplicationRecord
  belongs_to :produit
  belongs_to :commande

  has_many :sousarticles, dependent: :destroy

  scope :service_only, -> { joins(:produit).where(produits: { categorie_produit_id: CategorieProduit.where(service: true) }) }

  scope :location_only, -> { where(locvente: 'location') }
  scope :vente_only, -> { where(locvente: 'vente') }

  after_commit :after_article_save, on: [:create, :update, :destroy]

  # filtres analyses
  scope :filtredatedebut, -> (debut) { where("articles.created_at >= ?", debut) }
  scope :filtredatefin, -> (fin) { where("articles.created_at <= ?", fin) }
  

  def nom_complet
    "#{produit.nom}"
  end 

  def is_location
    locvente == "location" ? true : false 
  end

  def is_vente
    locvente == "vente" ? true : false 
  end

  private

  def after_article_save
    # Update the type_locvente field in the Commande based on the distinct locvente values

    commande = self.commande
    if commande.articles.any?
      locvente_values = commande.articles.distinct.pluck(:locvente)
      if locvente_values.include?('location') && locvente_values.include?('vente')
        commande.update(type_locvente: 'mixte')
      elsif locvente_values.include?('location')
        commande.update(type_locvente: 'location')
      elsif locvente_values.include?('vente')
        commande.update(type_locvente: 'vente')
      end
    end
  end

end
