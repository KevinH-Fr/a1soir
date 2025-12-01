class TypeRdv < ApplicationRecord
  # "code" est utilisé comme valeur stockée dans DemandeRdv#type_rdv
  # ex: "Découverte", "Essayage", "Retouche"

  validates :code, presence: true, uniqueness: true
  validates :duree_base_minutes, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :ordered, -> { order(:created_at) }

  # Retourne un tableau utilisable dans les selects Rails :
  # [[label, value], ...] => [["Découverte", "Découverte"], ...]
  def self.options_for_select
    ordered.map { |t| [t.code.to_s.titleize, t.code] }
  end
end


