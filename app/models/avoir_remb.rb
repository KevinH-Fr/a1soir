class AvoirRemb < ApplicationRecord
  belongs_to :commande

  TYPE_AVOIRREMB = ["avoir", "remboursement"].freeze
  MOYEN_PAIEMENT = PaiementRecu::MOYEN_PAIEMENT

  before_validation :clear_moyen_for_avoir

  validates :type_avoir_remb, presence: true, inclusion: { in: TYPE_AVOIRREMB }
  validates :moyen, inclusion: { in: MOYEN_PAIEMENT }, allow_blank: true
  validates :moyen, presence: true, on: :create, if: -> { type_avoir_remb == "remboursement" && commande && !commande.eshop? }

  scope :avoir_only, -> { where(type_avoir_remb: "avoir") }
  scope :remb_only, -> { where(type_avoir_remb: "remboursement") }

  private

  def clear_moyen_for_avoir
    self.moyen = nil if type_avoir_remb == "avoir"
  end
end
