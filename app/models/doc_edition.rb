class DocEdition < ApplicationRecord
  belongs_to :commande

  DOCUMENT_TYPES = ['commande', 'facture', 'facture simple']
  EDITION_TYPES = ['pdf', 'mail']

   
end
