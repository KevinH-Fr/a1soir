class Commande < ApplicationRecord
  belongs_to :client
  belongs_to :profile

  has_many :articles, dependent: :restrict_with_exception
  has_one :stripe_payment, dependent: :restrict_with_exception
  has_many :paiement_recus, dependent: :restrict_with_exception
  has_many :avoir_rembs, dependent: :restrict_with_exception
  has_many :meetings, dependent: :restrict_with_exception

  has_one_attached :qr_code, dependent: :destroy
  has_many :doc_editions, dependent: :destroy

  after_create :after_commande_create
  after_create :generate_qr
  
  # Callback pour mettre à jour la disponibilité des produits quand
  # les dates de location ou le statut devis changent.
  after_update :update_produits_availability_if_stock_inputs_changed

  scope :hors_devis, ->  { where("devis = ?", false)}
  scope :est_devis, ->  { where("devis = ?", true)}

  scope :non_retire, -> { where("statutarticles = ?", "non-retiré")}
  scope :retire, -> { where("statutarticles = ?", "retiré")}
  scope :rendu, -> { where("statutarticles = ?", "rendu")}


  # filtres analyses
  scope :filtredatedebut, -> (debut) { where("created_at >= ?", debut.beginning_of_day) }
  scope :filtredatefin, -> (fin) { where("created_at <= ?", fin.end_of_day) }

  scope :par_profile, ->(profile) { where(profile: profile) if profile.present? }
  scope :eshop_sales, -> { where(eshop: true) }


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
      "devis", "ref_commande", "eshop"
    ]
  end
  

  def self.ransackable_associations(auth_object = nil)
    ["articles", "avoir_rembs", "client", "meetings", "paiement_recus", "profile", "stripe_payment"]
  end

  ransacker :ref_commande, formatter: proc { |v| v } do |_parent|
    Arel.sql("CONCAT('C', 1000 + commandes.id)")
  end

  # Blocage si la commande a encore des lignes ou de la vie métier liée (articles → sous-articles inclus).
  def hard_destroy_allowed?
    return false if articles.exists?
    return false if paiement_recus.exists?
    return false if stripe_payment.present?
    return false if avoir_rembs.exists?
    return false if meetings.exists?
   # return false if doc_editions.exists?

    true
  end

  private

  def after_commande_create
    self.update(statutarticles: "non-retiré")
  end

  # Met à jour la disponibilité des produits concernés par la commande
  # quand des données qui influent le stock changent.
  def update_produits_availability_if_stock_inputs_changed
    return unless saved_change_to_debutloc? || saved_change_to_finloc? || saved_change_to_devis?

    # Produits liés aux articles/sous-articles de la commande.
    produits_ids = articles.pluck(:produit_id).uniq
    produits_ids += articles.joins(:sousarticles).pluck("sousarticles.produit_id").uniq

    # Produits liés au paiement eShop (si commande issue de Stripe).
    if stripe_payment.present?
      produits_ids += stripe_payment.stripe_payment_items.pluck(:produit_id).uniq
    end

    Produit.where(id: produits_ids.uniq).find_each do |produit|
      produit.update_today_availability
    end
  end

end
