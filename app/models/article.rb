class Article < ApplicationRecord
  belongs_to :produit
  belongs_to :commande

  has_many :sousarticles
  
  scope :location_only, -> { where(locvente: 'location') }
  scope :vente_only, -> { where(locvente: 'vente') }

  
  def nom_complet
    "#{produit.nom}"
  end 

end
