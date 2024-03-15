class Commande < ApplicationRecord
  belongs_to :client
  belongs_to :profile

  has_many :articles
  has_many :paiement_recus
  has_many :avoir_rembs
  has_many :meetings 
  
  after_create :after_commande_create

  scope :hors_devis, ->  { where("devis = ?", false)}
  scope :non_retire, -> { where("statutarticles = ?", "non-retiré")}
  scope :retire, -> { where("statutarticles = ?", "retiré")}
  scope :rendu, -> { where("statutarticles = ?", "rendu")}


  # filtres analyses
  scope :filtredatedebut, -> (debut) { where("created_at >= ?", debut) }
  scope :filtredatefin, -> (fin) { where("created_at <= ?", fin) }
  

  
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
