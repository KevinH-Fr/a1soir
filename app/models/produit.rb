class Produit < ApplicationRecord
  belongs_to :categorie_produit, optional: true
  belongs_to :fournisseur, optional: true

  belongs_to :couleur, optional: true
  belongs_to :taille, optional: true

  
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


  def generate_qr
      GenerateQr.call(self)
  end

end
