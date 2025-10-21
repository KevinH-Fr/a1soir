class Texte < ApplicationRecord
    has_rich_text :boutique
    has_rich_text :equipe
    has_rich_text :content
    has_rich_text :contact
    has_rich_text :horaire
    has_rich_text :adresse

    has_many_attached :carousel_images
    validate :carousel_images_are_valid

    private

    def carousel_images_are_valid
        # Ensure that there are attached images before running validations
        if carousel_images.attached? && carousel_images.any?
            carousel_images.each do |image|
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
  
end
