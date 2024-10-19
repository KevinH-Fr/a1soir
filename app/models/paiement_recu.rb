class PaiementRecu < ApplicationRecord
  belongs_to :commande

  validates :typepaiement, presence: :true
  
  TYPE_PAIEMENT = ["prix", "caution"]

  MOYEN_PAIEMENT = ["carte bleue", "espèces", "chèque", "virement"]

  scope :only_prix, -> { where(typepaiement: 'prix') }
  scope :only_caution, -> { where(typepaiement: 'caution') }

  scope :only_cb, -> { where(moyen: 'carte bleue') }
  scope :only_espece, -> { where(moyen: 'espèces') }
  scope :only_cheque, -> { where(moyen: 'chèque') }
  scope :only_virement, -> { where(moyen: 'virement') }

  # filtres analyses
  scope :filtredatedebut, -> (debut) { where("created_at >= ?", debut.beginning_of_day) }
  scope :filtredatefin, -> (fin) { where("created_at <= ?", fin.end_of_day) }
  
end
