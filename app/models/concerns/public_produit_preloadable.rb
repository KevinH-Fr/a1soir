# frozen_string_literal: true

module PublicProduitPreloadable
  extend ActiveSupport::Concern

  # Attachments rendered on catalogue cards (_produit + _carousel)
  PUBLIC_LISTING_ATTACHMENTS = %i[image1 video1 images].freeze

  # Cart / cabine: thumbnail only
  PUBLIC_CART_ATTACHMENTS = %i[image1].freeze

  class_methods do
    def for_public_listing_cards
      with_attached_image1
        .with_attached_video1
        .with_attached_images
    end

    def for_public_cart_thumbnail
      with_attached_image1
    end
  end
end
