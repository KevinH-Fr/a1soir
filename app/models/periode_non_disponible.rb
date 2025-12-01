class PeriodeNonDisponible < ApplicationRecord
  self.table_name = "periodes_non_disponibles"
  
  
  validates :date_debut, :date_fin, presence: true
  validate :date_fin_after_date_debut

  # true dans la BDD = "recurrence" (revient chaque année)
  # on garde le même nom dans le modèle que dans la migration

  scope :recurrentes, -> { where(recurrence: true) }
  scope :exceptionnelles, -> { where(recurrence: false) }

  private

  def date_fin_after_date_debut
    return if date_debut.blank? || date_fin.blank?
    return if date_fin >= date_debut

    errors.add(:date_fin, "doit être postérieure ou égale à la date de début")
  end
end


