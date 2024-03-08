class Commande < ApplicationRecord
  belongs_to :client
  belongs_to :profile

  has_many :articles
  has_many :paiement_recus
  has_many :avoir_rembs
  has_many :meetings 
  
  after_create :after_commande_create

  def full_name
    "ref#{id}_#{nom}"
  end

  def ref_commande
    "C#{ 1000 + id }"
  end

  def is_location
    type_locvente == "location" ? true : false 
  end

  def is_vente
    type_locvente == "vente" ? true : false 
  end
  
  # ajouter is mixte ?


  private

  def after_commande_create
    self.update(statutarticles: "non-retiré")
  end

end
