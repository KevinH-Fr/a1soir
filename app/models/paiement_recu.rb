class PaiementRecu < ApplicationRecord
  belongs_to :commande

  validates :typepaiement, presence: :true
  TYPE_PAIEMENT = ["prix", "caution"]

end
