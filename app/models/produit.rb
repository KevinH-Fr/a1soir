class Produit < ApplicationRecord
  belongs_to :categorie_produit, optional: true
  belongs_to :type_produit, optional: true

  belongs_to :fournisseur, optional: true

  belongs_to :couleur, optional: true
  belongs_to :taille, optional: true

  has_many :ensembles

  has_one_attached :image1
  has_many_attached :images
  has_one_attached :qr_code

  after_create :generate_qr

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

  def generate_qr
      GenerateQr.call(self)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["categorie_produit_id", "caution", "couleur_id", "created_at", "dateachat", "description", "fournisseur_id", "handle", "id", "id_value", "nom", "prixachat", "prixlocation", "prixvente", "quantite", "reffrs", "taille_id", "updated_at"]
  end

end
