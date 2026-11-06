# frozen_string_literal: true

module ProduitCardPreloadable
  extend ActiveSupport::Concern

  CARD_INCLUDES = [
    :couleur,
    :taille,
    :fournisseur,
    :categorie_produits,
    :rubrique_costumes,
    { image1_attachment: :blob },
    { images_attachments: :blob },
    { qr_code_attachment: :blob }
  ].freeze
end
