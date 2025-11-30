class DemandeRdv < ApplicationRecord

  has_one :meeting, dependent: :destroy
  
  STATUT = [
    ["soumis", "soumis"],
    ["confirmé", "confirmé"],
    ["annulé", "annulé"]
  ].freeze
      
  # Validations
  validates :nom, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :telephone, presence: true
  validates :date_rdv, presence: true

  # Callbacks
  after_update :sync_meeting_with_statut

  # Ransackable attributes for admin search
  def self.ransackable_attributes(auth_object = nil)
    ["commentaire", "created_at", "date_rdv", "email", "id", "id_value", "nom", "prenom", "statut", "telephone", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["meeting"]
  end

  # Helper methods
  def full_name_with_email
    "#{nom} (#{email})"
  end
  
  # Retourne le nom complet (prénom + nom) si prénom présent, sinon juste le nom
  def full_name
    [prenom, nom].compact.join(" ")
  end
  

  # Créneaux horaires disponibles
  def self.creneaux_horaires
    ["10:00", "11:00", "15:00", "16:00", "17:00"]
  end

  # Périodes non disponibles (dates exclues) - se répètent chaque année
  # Période du 24 décembre au 2 janvier (se répète chaque année)
  # Format: array de hashes avec :debut et :fin (dates au format string "YYYY-MM-DD")
  def self.periodes_non_disponibles
    current_year = Date.today.year
    # Retourner les périodes pour les 2 prochaines années
    (current_year..current_year + 1).map do |year|
      { 
        debut: "#{year}-12-24", 
        fin: "#{year + 1}-01-02" 
      }
    end
  end

  # Récupère tous les créneaux occupés pour les prochaines dates (format: { "YYYY-MM-DD" => ["HH:MM", ...] })
  # Un créneau est considéré comme occupé uniquement s'il y a 2 rendez-vous ou plus
  def self.creneaux_occupes_par_date(days_ahead: 90)
    start_date = Date.today
    end_date = start_date + days_ahead.days
    
    Meeting.where(datedebut: start_date.beginning_of_day..end_date.end_of_day)
           .group_by { |m| [m.datedebut.to_date, m.datedebut.strftime("%H:%M")] }
           .select { |_key, meetings| meetings.count >= 2 }
           .group_by { |(date, _time), _meetings| date }
           .transform_values { |items| items.map { |(_, time), _| time }.uniq }
           .transform_keys { |date| date.strftime("%Y-%m-%d") }
  end

  # Récupère les créneaux occupés pour une date donnée depuis les Meetings
  # Un créneau est considéré comme occupé uniquement s'il y a 2 rendez-vous ou plus
  def self.creneaux_occupes_pour_date(date)
    date_obj = date.is_a?(String) ? Date.parse(date) : date
    
    Meeting.where(datedebut: date_obj.beginning_of_day..date_obj.end_of_day)
           .group_by { |m| m.datedebut.strftime("%H:%M") }
           .select { |_time, meetings| meetings.count >= 2 }
           .keys
  end

  # Récupère les créneaux disponibles pour une date donnée
  def self.creneaux_disponibles_pour_date(date)
    creneaux_horaires - creneaux_occupes_pour_date(date)
  end

  # Construit les attributs nécessaires pour initialiser un client à partir de la demande
  def to_client_attributes
    {
      prenom: prenom,
      nom: nom,
      tel: telephone,
      mail: email
    }.select { |_key, value| value.present? }
  end

  private

  # Synchronise le meeting avec le statut de la demande
  # - Si statut = "confirmé" : crée ou met à jour le meeting
  # - Sinon : supprime le meeting s'il existe
  def sync_meeting_with_statut
    if statut == "confirmé"
      create_or_update_meeting
    else
      destroy_meeting_if_exists
    end
  end

  # Crée ou met à jour le meeting pour une demande confirmée
  def create_or_update_meeting
    return unless date_rdv.present?
    
    # Trouver ou créer le client
    client, _created = Client.create_from_demande(self)
    return unless client&.persisted?
    
    # Calculer la date de fin (1 heure après le début)
    # TODO: adapter pour dynamique en fonction du type de rdv
    datedebut = date_rdv
    datefin = datedebut + 1.hour
    
    # Créer ou mettre à jour le meeting avec le client associé
    if meeting.present?
      meeting.update(
        nom: "RDV depuis site",
        datedebut: datedebut,
        datefin: datefin,
        lieu: "boutique",
        client_id: client.id
      )
    else
      create_meeting(
        nom: "RDV depuis site",
        datedebut: datedebut,
        datefin: datefin,
        lieu: "boutique",
        demande_rdv_id: id,
        client_id: client.id
      )
    end
  end

  # Supprime le meeting si la demande n'est plus confirmée
  def destroy_meeting_if_exists
    meeting&.destroy
  end

end

