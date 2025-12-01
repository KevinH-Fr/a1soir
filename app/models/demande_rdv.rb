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
  validates :type_rdv, presence: true
  validates :nombre_personnes, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }
  validate :type_rdv_must_be_valid

  # Callbacks
  after_update :sync_meeting_with_statut

  # Ransackable attributes for admin search
  def self.ransackable_attributes(auth_object = nil)
    ["commentaire", "created_at", "date_rdv", "email", "id", "id_value", "nom", "nombre_personnes", "prenom", "statut", "telephone", "type_rdv", "updated_at"]
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
  

  # Créneaux horaires disponibles (configurés via ParametreRdv)
  def self.creneaux_horaires
    ParametreRdv.current&.creneaux_horaires_list.presence || ["10:00", "11:00", "15:00", "16:00", "17:00"]
  end

  # Retourne les jours de la semaine avec 0 capacité (à désactiver dans le calendrier)
  # Format: array de numéros de jours (0 = dimanche, 1 = lundi, ..., 6 = samedi)
  def self.jours_desactives
    config = ParametreRdv.current
    return [] unless config

    jours = []
    # En Ruby : 0 = dimanche, 1 = lundi, ..., 6 = samedi
    jours << 0 if (config.nb_rdv_simultanes_dimanche || 0) == 0
    jours << 1 if (config.nb_rdv_simultanes_lundi || 0) == 0
    jours << 2 if (config.nb_rdv_simultanes_mardi || 0) == 0
    jours << 3 if (config.nb_rdv_simultanes_mercredi || 0) == 0
    jours << 4 if (config.nb_rdv_simultanes_jeudi || 0) == 0
    jours << 5 if (config.nb_rdv_simultanes_vendredi || 0) == 0
    jours << 6 if (config.nb_rdv_simultanes_samedi || 0) == 0
    jours
  end

  # Périodes non disponibles (dates exclues)
  # Format: array de hashes avec :debut et :fin (dates au format string "YYYY-MM-DD")
  def self.periodes_non_disponibles
    today = Date.today
    current_year = today.year
    next_year = current_year + 1

    PeriodeNonDisponible.all.flat_map do |periode|
      if periode.recurrence
        # Période récurrente : on la projette sur l'année courante et la suivante
        [current_year, next_year].map do |year|
          debut = Date.new(year, periode.date_debut.month, periode.date_debut.day)
          fin   = Date.new(year, periode.date_fin.month,   periode.date_fin.day)
          { debut: debut.strftime("%Y-%m-%d"), fin: fin.strftime("%Y-%m-%d") }
        end
      else
        # Période exceptionnelle : on utilise les dates telles quelles
        { debut: periode.date_debut.strftime("%Y-%m-%d"), fin: periode.date_fin.strftime("%Y-%m-%d") }
      end
    end
  end

  # Récupère tous les créneaux occupés pour les prochaines dates (format: { "YYYY-MM-DD" => ["HH:MM", ...] })
  # Un créneau est considéré comme occupé uniquement s'il atteint la capacité max définie dans ParametreRdv
  def self.creneaux_occupes_par_date(days_ahead: 90)
    start_date = Date.today
    end_date = start_date + days_ahead.days

    config = ParametreRdv.current
    return {} unless config

    meetings_grouped = Meeting.where(datedebut: start_date.beginning_of_day..end_date.end_of_day)
                              .group_by { |m| [m.datedebut.to_date, m.datedebut.strftime("%H:%M")] }

    # On garde uniquement les créneaux qui atteignent la capacité max pour ce jour
    saturated_slots = meetings_grouped.select do |(date, _time), meetings|
      capacity = config.nb_rdv_simultanes_for(date)
      capacity.positive? && meetings.count >= capacity
    end

    saturated_slots
      .group_by { |(date, _time), _meetings| date }
      .transform_values { |items| items.map { |(_, time), _| time }.uniq }
      .transform_keys { |date| date.strftime("%Y-%m-%d") }
  end

  # Récupère les créneaux occupés pour une date donnée depuis les Meetings
  # Un créneau est considéré comme occupé uniquement s'il atteint la capacité max définie dans ParametreRdv
  def self.creneaux_occupes_pour_date(date)
    date_obj = date.is_a?(String) ? Date.parse(date) : date

    config = ParametreRdv.current
    return [] unless config

    capacity = config.nb_rdv_simultanes_for(date_obj)
    return [] unless capacity.positive?

    Meeting.where(datedebut: date_obj.beginning_of_day..date_obj.end_of_day)
           .group_by { |m| m.datedebut.strftime("%H:%M") }
           .select { |_time, meetings| meetings.count >= capacity }
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

  # Calcule la durée du rendez-vous en fonction du type et du nombre de personnes
  # Retourne la durée en minutes
  def duree_rdv_minutes
    return 60 unless type_rdv.present? # Durée par défaut si type non défini
    
    type_record = TypeRdv.find_by(code: type_rdv)
    duree_base = type_record&.duree_base_minutes || 60

    personnes_supp = [(nombre_personnes || 1) - 1, 0].max # Nombre de personnes supplémentaires

    config = ParametreRdv.current
    minutes_supp = config&.minutes_par_personne_supp || 15

    duree_base + (personnes_supp * minutes_supp)
  end

  # Retourne la durée du rendez-vous en heures (format décimal)
  def duree_rdv_heures
    duree_rdv_minutes / 60.0
  end

  # Retourne la durée formatée (ex: "1h30", "45min")
  def duree_rdv_formatee
    minutes = duree_rdv_minutes
    heures = minutes / 60
    mins_restantes = minutes % 60
    
    if heures > 0 && mins_restantes > 0
      "#{heures}h#{mins_restantes.to_s.rjust(2, '0')}"
    elsif heures > 0
      "#{heures}h"
    else
      "#{minutes}min"
    end
  end

  private

  # Vérifie que type_rdv correspond bien à un TypeRdv existant
  def type_rdv_must_be_valid
    return if type_rdv.blank?
    return if TypeRdv.exists?(code: type_rdv)

    errors.add(:type_rdv, "n'est pas un type de rendez-vous valide")
  end

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
    
    # Calculer la date de fin en fonction du type de RDV et du nombre de personnes
    datedebut = date_rdv
    datefin = datedebut + duree_rdv_minutes.minutes
    
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

