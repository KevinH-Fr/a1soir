class DemandeRdv < ApplicationRecord
  # Enums (gérés en string)
  enum :statut, {
    soumis: "soumis",
    confirme: "confirmé",
    annule: "annulé"
  }, suffix: true
      
  # Validations
  validates :nom, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :telephone, presence: true
  validates :date_rdv, presence: true

  # Ransackable attributes for admin search
  def self.ransackable_attributes(auth_object = nil)
    ["commentaire", "created_at", "date_rdv", "email", "id", "id_value", "nom", "statut", "telephone", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  # Helper methods
  def full_name_with_email
    "#{nom} (#{email})"
  end

  # Créneaux horaires disponibles
  def self.creneaux_horaires
    ["10:00", "11:00", "15:00", "16:00", "17:00"]
  end

  # Périodes non disponibles (dates exclues)
  # Format: array de hashes avec :debut et :fin (dates au format string "YYYY-MM-DD")
  def self.periodes_non_disponibles
    [
      # Exemple: { debut: "2024-12-24", fin: "2024-12-31" }
    ]
  end

end

