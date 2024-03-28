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
  
  EVENEMENTS_OPTIONS = ['mariage', 'soirée', 'divers']

  
  def full_name
    "#{ref_commande} #{created_at.strftime("%d/%m/%Y")}"
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

  def full_event
    "#{typeevent}" " #{dateevent.strftime("%d/%m/%Y") if dateevent} "
  end
  
  def date_retenue
    debutloc.present? ? debutloc : Date.today
  end
  # ajouter is mixte ?

  def self.ransackable_attributes(auth_object = nil)
    ["id", "nom", "montant", "description", "client_id", "debutloc", "finloc", "dateevent", "statutarticles", "typeevent", "profile_id", "commentaires", "commentaires_doc", "type_locvente", "devis"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["articles", "avoir_rembs", "client", "meetings", "paiement_recus", "profile"]
  end
  
  private

  def after_commande_create
    self.update(statutarticles: "non-retiré")
  end

end
