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

  has_many_attached :images
  validate :images_are_valid

  has_one_attached :qr_code

  before_validation :generate_handle

  before_validation :fix_quantity_for_service
  before_validation :fix_quantity_for_ensemble

  after_create :generate_qr
  #after_create :set_initial_vente_price

  after_initialize :set_default_poids

  # After save (create or update), call the method to handle product/price sync with Stripe
  after_save :sync_stripe_product_and_price

  scope :is_ensemble, -> { joins(:type_produit).where(type_produits: { nom: 'ensemble' }) }
  scope :is_service, -> { joins(:categorie_produits).where(categorie_produits: { service: true }) }
  scope :not_service, -> { joins(:categorie_produits).where(categorie_produits: { service: [false, nil] }) }
  scope :actif, -> { where(actif: true) } 
  scope :eshop_diffusion, -> { where(eshop: true) }

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
    "#{nom} | #{reffrs} | #{couleur&.nom} | #{taille&.nom}"
  end 

  def nom_couleur_taille
    [nom, couleur&.nom, taille&.nom].compact.join(' | ')
  end
  

  def generate_qr
      GenerateQr.call(self)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["categorie_produit_id", "caution", "couleur_id", "created_at", "dateachat", "description", "fournisseur_id", "handle", "id", "id_value", "nom", "prixachat", "prixlocation", "prixvente", "quantite", "reffrs", "taille_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    super +  ["articles", "categorie_produits", "couleur", "ensembles", "fournisseur", "taille", "type_produit"]
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
  
  # Sync the product and price with Stripe on create or update
  def sync_stripe_product_and_price
    if stripe_product_id.present? && stripe_price_id.present?
      # Update product and price if Stripe IDs already exist
      Stripe::Product.update(self.stripe_product_id, {
        name: self.nom,
        description: self.description
      })

      # Deactivate the old price by setting `active` to false
      Stripe::Price.update(self.stripe_price_id, { active: false })
      
      # Create a new price with the updated `unit_amount`
      new_stripe_price = Stripe::Price.create({
        product: self.stripe_product_id,
        unit_amount: (self.prixvente * 100).to_i,  # Convert price to cents
        currency: 'eur',  # Adjust as needed
      })

      # Save the new price ID to the model
      self.update_column(:stripe_price_id, new_stripe_price.id)
      
    else
      # Create product and price in Stripe if not already present
      stripe_product = Stripe::Product.create({
        name: self.nom,
        description: self.description
      })

      stripe_price = Stripe::Price.create({
        unit_amount: (self.prixvente * 100).to_i,
        currency: 'eur',
        product: stripe_product.id
      })

      # Store the Stripe IDs in the local database
      self.update_column(:stripe_product_id, stripe_product.id)
      self.update_column(:stripe_price_id, stripe_price.id)
    end
  end

end
