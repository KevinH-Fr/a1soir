class Texte < ApplicationRecord
    has_rich_text :boutique
    has_rich_text :equipe
    has_rich_text :content
    has_rich_text :contact
    has_rich_text :horaire
    has_rich_text :horaire_periode_speciale
    has_rich_text :adresse

    has_many_attached :carousel_images
    validate :carousel_images_are_valid

    private

    def carousel_images_are_valid
      return unless carousel_images.attached? && carousel_images.any?

      carousel_images.each do |image|
        if image.byte_size > 5.megabytes
          errors.add(:images, :file_too_big_named, filename: image.filename.to_s, max: "5 Mo")
        end

        unless image.content_type.in?(%w[image/jpeg image/png image/gif image/jpg image/webp])
          errors.add(:images, :file_invalid_image_named, filename: image.filename.to_s)
        end
      end
    end
  
end
