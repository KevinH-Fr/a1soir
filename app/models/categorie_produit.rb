class CategorieProduit < ApplicationRecord
    has_and_belongs_to_many :produits

    before_validation :downcase_nom
    validates :nom, presence: true, uniqueness: { case_sensitive: false }

    has_one_attached :image1
    validate :image1_is_valid

    scope :not_service, -> { where(service: [false, nil] ) }

    def self.ransackable_attributes(auth_object = nil)
        ["nom"]
    end

    def default_image
        if image1.attached?
          image1
        else
          '/images/no_photo.png'
        end
    end

    def is_service?
      categorie_produits.where(service: true).exists?
    end

    private

    def downcase_nom
        self.nom = nom.downcase if nom.present?
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


end
