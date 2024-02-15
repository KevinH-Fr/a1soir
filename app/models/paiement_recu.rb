class PaiementRecu < ApplicationRecord
  belongs_to :commande

  validates :typepaiement, presence: :true
  
  TYPE_PAIEMENT = ["prix", "caution"]

  scope :only_prix, -> { where(typepaiement: 'prix') }
  scope :only_caution, -> { where(typepaiement: 'caution') }

end
