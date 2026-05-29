class DocEdition < ApplicationRecord
  belongs_to :commande

  DOCUMENT_TYPES = ['commande', 'facture', 'facture simple']
  EDITION_TYPES = ['pdf', 'mail']

  validate :doc_type_allowed_for_commande

  def self.document_types_for(commande)
    return DOCUMENT_TYPES unless commande&.eshop?

    ["facture"]
  end

  private

  def doc_type_allowed_for_commande
    return if commande.blank? || doc_type.blank?

    return if self.class.document_types_for(commande).include?(doc_type)

    errors.add(:doc_type, :eshop_doc_type)
  end
end
