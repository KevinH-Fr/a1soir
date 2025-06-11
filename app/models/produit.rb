class Produit < ApplicationRecord
  has_and_belongs_to_many :categorie_produits
    
  belongs_to :type_produit, optional: true

  belongs_to :fournisseur, optional: true

  belongs_to :couleur, optional: true
  belongs_to :taille, optional: true

  validates :nom, presence: true

  has_many :articles, dependent: :destroy
  has_many :sousarticles, dependent: :destroy

  has_many :ensembles

  has_one_attached :image1
  validate :image1_is_valid

  has_one_attached :video1
  validate :video1_is_valid


  has_many_attached :images
  validate :images_are_valid

  has_one_attached :qr_code

  before_validation :generate_handle

  before_validation :fix_quantity_for_service
  before_validation :fix_quantity_for_ensemble

  after_create :generate_qr

  after_create :set_default_caution, if: -> { caution.blank? }

  #after_create :set_initial_vente_price

  after_initialize :set_default_poids

  scope :is_ensemble, -> { joins(:type_produit).where(type_produits: { nom: 'ensemble' }) }
  scope :is_service, -> { joins(:categorie_produits).where(categorie_produits: { service: true }) }
  scope :not_service, -> { joins(:categorie_produits).where(categorie_produits: { service: [false, nil] }) }
  scope :actif, -> { where(actif: true) } 
  scope :inactif, -> { where(actif: [false, nil]) }
  scope :eshop_diffusion, -> { where(eshop: true) }

  scope :by_categorie, ->(categorie) { joins(:categorie_produits).where(categorie_produits: { id: categorie.id }) }
  scope :by_taille, ->(taille) { where(taille: taille) }
  scope :by_couleur, ->(couleur) { where(couleur: couleur) }


  # Scope to filter by prixvente or prixlocation being less than or equal to prixmax
  scope :by_prixmax, ->(prixmax) { 
    where("prixvente <= ? OR prixlocation <= ?", prixmax, prixmax) if prixmax.present? 
  }
  
   # Scope to filter by type (Vente or Location)
   scope :by_type, ->(type) {
    case type
    when "Vente"
      where("prixvente > 0")
    when "Location"
      where("prixlocation > 0")
    else
      all
    end
   }
   
  # filtres analyses
  scope :filtredatedebut, -> (debut) { where("created_at >= ?", debut.beginning_of_day) }
  scope :filtredatefin, -> (fin) { where("created_at <= ?", fin.end_of_day) }

  
  
  def full_name
    nom
  end

  def default_image
    if image1.attached?
      image1
    else
      '/images/no_photo.png'
    end
  end

  def nom_ref_couleur_taille 
    [nom, reffrs, couleur&.nom, taille&.nom].compact.join(' | ')
  end 

  def nom_couleur_taille
    [nom, couleur&.nom, taille&.nom].compact.join(' | ')
  end
  

  def generate_qr
      GenerateQr.call(self)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["categorie_produit_id", "caution", "couleur_id", "created_at", 
      "dateachat", "description", "handle", "id", "id_value", "nom", 
      "prixachat", "prixlocation", "prixvente", "quantite", "reffrs", 
      "taille_id", "fournisseur_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    super +  ["articles", "categorie_produits", "couleur", "ensembles", 
              "fournisseur", "taille", "type_produit"]
  end

  # def self.ransackable_associations(auth_object = nil)
  #   ["couleur", "taille", "fournisseur", "categorie_produits", "type_produit", "articles", "ensembles"]
  # end

  def to_builder
    Jbuilder.new do |json|
      json.price stripe_price_id
      json.quantity 1
    end
  end


  #gestion stock du produit

  def is_service?
    categorie_produits.where(service: true).exists?
  end

  def is_ensemble?
    type_produit.nom == 'ensemble' if type_produit
  end
  
  def total_vendus
    total_quantite = Article.joins(:commande, :produit)
  #  .merge(Produit.not_service)
    .merge(Commande.hors_devis)
    .vente_only
    .where(produit_id: id)
    .sum(:quantite)

    total_quantite += Sousarticle.joins(article: [:commande, :produit])
    .where(produit_id: id)
  #  .merge(Produit.not_service)
    .merge(Commande.hors_devis)
    .vente_only
    .count

    total_quantite
  
  end
  
  def total_vendus_eshop

    # Stripe payments (only if marked as 'paid')
    total_quantite = StripePaymentItem
    .joins(:stripe_payment)
    .where(stripe_payments: { status: 'paid' }, produit_id: id)
    .count

    total_quantite
  
  end

  def statut_disponibilite(datedebut, datefin)
    
    if self.is_service? || self.is_ensemble?
      initial_stock = 1
      loues_a_date = 0
      vendus = 0
      vendus_eshop = 0
      disponibles = 1
    else
      loues_a_date = Article.joins(:commande)
                            .where(produit_id: id)
                            .where("commandes.debutloc <= ? AND commandes.finloc >= ?", datedebut, datefin)
                            .merge(Commande.hors_devis)                         
                            .location_only.sum(:quantite).to_i
  
      loues_a_date += Sousarticle.joins(article: :commande)
                                .where(produit_id: id)
                                .merge(Commande.hors_devis)
                                .where("commandes.debutloc <= ? AND commandes.finloc >= ?", datedebut, datefin)
                                .location_only.sum(:quantite).to_i

      initial_stock = self.quantite.to_i
      vendus = total_vendus + total_vendus_eshop
    end

    disponibles = initial_stock - (loues_a_date + vendus)
  
      # returning a hash with all the necessary keys
      {
        produit_id: id,
        nom: nom,
        datedebut: datedebut,
        datefin: datefin,
        initial: initial_stock,
        loues_a_date: loues_a_date,
        vendus: vendus,
        vendus_eshop: total_vendus_eshop,
        disponibles: disponibles,
        statut: disponibles > 0 ? "disponible" : "indisponible"
      }
  end

  

  private

  # def set_initial_vente_price
  #   if prixachat && AdminParameter.first
  #     montant_vente = prixachat * (1 + AdminParameter.first.tx_tva.to_f / 100) * AdminParameter.first.coef_prix_achat_vente
  #     self.update(prixvente: montant_vente )
  #   end
  # end

  def generate_handle
    # handle used to regroup products for colors and tailles
    # quid utiliser nom ou reffrs
    return unless nom

    # Use ActiveSupport's parameterize method to generate the handle
    self.handle = nom.parameterize
  end

  def fix_quantity_for_service 
    #if produit is a service empty the quantity
    if categorie_produits.first&.service 
      self.quantite = 1
    end
  end

  def fix_quantity_for_ensemble
    #if produit is an ebsemble empty the quantity
    if type_produit&.nom == "ensemble" 
      self.quantite = 1
    end
  end

  def image1_is_valid
    if image1.attached?
      # Check file size (5MB max)
      if image1.byte_size > 5.megabytes
        errors.add(:image1, 'is too big. Maximum size is 5MB.')
      end

      # Check file type (allow only images)
      unless image1.content_type.in?(%w[image/jpeg image/png image/gif image/jpg image/webp])
        errors.add(:image1, 'must be a JPG, JPEG, PNG, WEBP or GIF image.')
      end
    end
  end
  
  def video1_is_valid
    if video1.attached?
      if video1.byte_size > 50.megabytes
        errors.add(:video1, 'is too big. Maximum size is 50MB.')
      end

      # Check file type (allow only images)
      unless video1.content_type.in?(%w[video/mp4 video/webm])
        errors.add(:video1, 'must be a MP4 or WebM video.')
      end
    end
  end

  def images_are_valid
    # Ensure that there are attached images before running validations
    if images.attached? && images.any?
      images.each do |image|
        # Check file size (5MB max for each image)
        if image.byte_size > 5.megabytes
          errors.add(:images, "#{image.filename} is too big. Maximum size is 5MB.")
        end
  
        # Check file type (allow only images)
        unless image.content_type.in?(%w[image/jpeg image/png image/gif image/jpg image/webp])
          errors.add(:images, "#{image.filename} must be a JPG, JPEG, PNG, WEBP or GIF image.")
        end
      end
    end
  end

  def set_default_poids
    self.poids ||= 2000
  end

  def set_default_caution
    return unless prixlocation.present?
    update_column(:caution, (prixlocation.to_f * 3.5).round)
  end

end
