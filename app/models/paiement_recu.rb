class PaiementRecu < ApplicationRecord
  belongs_to :commande

  validates :typepaiement, presence: :true
  
  TYPE_PAIEMENT = ["prix", "caution"]

  MOYEN_PAIEMENT = ["carte bleue", "espèces", "chèque", "virement"]

  scope :only_prix, -> { where(typepaiement: 'prix') }
  scope :only_caution, -> { where(typepaiement: 'caution') }

  # filtres analyses
  scope :filtredatedebut, -> (debut) { where("created_at >= ?", debut.beginning_of_day) }
  scope :filtredatefin, -> (fin) { where("created_at <= ?", fin.end_of_day) }
  
end
