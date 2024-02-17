class AvoirRemb < ApplicationRecord
  belongs_to :commande

  TYPE_AVOIRREMB = ["avoir", "remboursement"]

  scope :avoir_only, -> { where(type_avoir_remb: 'avoir') }
  scope :remb_only, -> { where(type_avoir_remb: 'remboursement') }

end
