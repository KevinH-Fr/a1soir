class Commande < ApplicationRecord
  belongs_to :client
  belongs_to :profile

  has_many :articles, dependent: :destroy
  has_many :paiement_recus, dependent: :destroy
  has_many :avoir_rembs, dependent: :destroy
  has_many :meetings, dependent: :destroy

  has_one_attached :qr_code, dependent: :destroy
  has_many :doc_editions, dependent: :destroy

  after_create :after_commande_create
  after_create :generate_qr

  scope :hors_devis, ->  { where("devis = ?", false)}
  scope :non_retire, -> { where("statutarticles = ?", "non-retiré")}
  scope :retire, -> { where("statutarticles = ?", "retiré")}
  scope :rendu, -> { where("statutarticles = ?", "rendu")}


  # filtres analyses
  scope :filtredatedebut, -> (debut) { where("created_at >= ?", debut.beginning_of_day) }
  scope :filtredatefin, -> (fin) { where("created_at <= ?", fin.end_of_day) }

  scope :par_profile, ->(profile) { where(profile: profile) if profile.present? }


  EVENEMENTS_OPTIONS = ['mariage', 'soirée', 'festival de Cannes', 'divers']

  def full_name
    "#{ref_commande} #{created_at.strftime("%d/%m/%Y")}"
  end

  def full_name_with_client
    "#{ref_commande} #{client.full_name} #{created_at.strftime("%d/%m/%Y")}"
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

  def label_dates_location 
    if debutloc && finloc
      "Location du #{debutloc.strftime("%d/%m/%Y")} au #{finloc.strftime("%d/%m/%Y")}"
    end
  end

  def generate_qr
    GenerateQr.call(self)
  end

  def next_upcoming_meeting
    meetings.where('datedebut > ?', Time.now).order(datedebut: :asc).first
  end

  def self.ransackable_attributes(auth_object = nil)
    [
      "id", "nom", "montant", "description", "client_id",
      "debutloc", "finloc", "dateevent", "statutarticles", "typeevent",
      "profile_id", "commentaires", "commentaires_doc", "type_locvente",
      "devis", "ref_commande" # <-- Ajouté ici
    ]
  end
  

  def self.ransackable_associations(auth_object = nil)
    ["articles", "avoir_rembs", "client", "meetings", "paiement_recus", "profile"]
  end

  ransacker :ref_commande, formatter: proc { |v| v } do |_parent|
    Arel.sql("CONCAT('C', 1000 + commandes.id)")
  end
  

  private

  def after_commande_create
    self.update(statutarticles: "non-retiré")
  end

end
