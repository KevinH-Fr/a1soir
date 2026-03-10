class DemandeRdv < ApplicationRecord

  has_one :meeting, dependent: :destroy
  has_one :demande_cabine_essayage, dependent: :destroy

  STATUT = [
    ["soumis",    "soumis"],
    ["confirmé",  "confirmé"],
    ["annulé",    "annulé"]
  ].freeze

  enum :evenement, {
    mariage: "mariage",
    soiree:  "soirée",
    autre:   "autre"
  }, prefix: true

  # Validations
  validates :nom,             presence: true
  validates :email,           presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :telephone,       presence: true
  validates :date_rdv,        presence: true
  validates :type_rdv,        presence: true
  validates :evenement,       presence: true
  validates :date_evenement,  presence: true
  validates :nombre_personnes, presence: true,
                               numericality: { only_integer: true,
                                               greater_than_or_equal_to: 1,
                                               less_than_or_equal_to: 10 }
  validate :type_rdv_must_be_valid

  # Callbacks
  after_update :sync_meeting_with_statut

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    %w[commentaire created_at date_evenement date_rdv email evenement id id_value
       nom nombre_personnes prenom statut telephone type_rdv updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[demande_cabine_essayage meeting]
  end

  # ---- Helpers d'instance ------------------------------------------------

  def full_name_with_email
    "#{nom} (#{email})"
  end

  # Retourne "Prénom Nom" si le prénom est renseigné, sinon juste le nom.
  def full_name
    [prenom, nom].compact.join(" ")
  end

  # Pré-sélectionne le type "Essayage" si aucun type n'est déjà défini.
  def set_type_essayage
    return if type_rdv.present?

    essayage_type = TypeRdv.find_by("LOWER(code) = ?", "essayage")
    self.type_rdv = essayage_type.code if essayage_type.present?
  end

  # Construit les attributs pour initialiser un Client depuis la demande.
  def to_client_attributes
    { prenom: prenom, nom: nom, tel: telephone, mail: email }
      .select { |_key, value| value.present? }
  end

  # ---- Durée du rendez-vous ----------------------------------------------

  # Calcule la durée du RDV (en minutes) selon le type et le nombre de personnes.
  def duree_rdv_minutes
    type_record = TypeRdv.find_by(code: type_rdv)
    duree_base  = type_record&.duree_base_minutes || 60

    personnes_supp = [(nombre_personnes || 1) - 1, 0].max
    minutes_supp   = ParametreRdv.current&.minutes_par_personne_supp || 15

    duree_base + (personnes_supp * minutes_supp)
  end

  def duree_rdv_heures
    duree_rdv_minutes / 60.0
  end

  # Retourne la durée formatée : "1h30", "2h", "45min", etc.
  def duree_rdv_formatee
    minutes        = duree_rdv_minutes
    heures         = minutes / 60
    mins_restantes = minutes % 60

    if heures > 0 && mins_restantes > 0
      "#{heures}h#{mins_restantes.to_s.rjust(2, '0')}"
    elsif heures > 0
      "#{heures}h"
    else
      "#{minutes}min"
    end
  end

  # ---- Méthodes de classe pour les créneaux ------------------------------

  # Créneaux autorisés pour une date donnée selon la config du jour.
  # Retourne DEFAULT_CRENEAUX si aucune config n'existe.
  def self.creneaux_horaires_pour_date(date)
    date_obj = date.is_a?(String) ? Time.zone.parse(date) : date
    config   = ParametreRdv.current
    return ParametreRdv::DEFAULT_CRENEAUX unless config

    config.creneaux_for(date_obj)
  end

  # Créneaux autorisés pour les <days_ahead> prochains jours.
  # Retourne un Hash { "YYYY-MM-DD" => ["HH:MM", …] } (seules les dates avec des créneaux sont incluses).
  def self.creneaux_autorises_par_date(days_ahead: 90)
    config = ParametreRdv.current
    return {} unless config

    (Date.today..(Date.today + days_ahead)).each_with_object({}) do |date, result|
      liste = config.creneaux_for(date)
      result[date.strftime("%Y-%m-%d")] = liste if liste.present?
    end
  end

  # Créneaux occupés pour une date précise.
  # Un créneau est occupé dès que le nombre de meetings chevauchants atteint la capacité max.
  def self.creneaux_occupes_pour_date(date)
    date_obj = date.is_a?(String) ? Time.zone.parse(date) : date
    config   = ParametreRdv.current
    return [] unless config

    capacity = config.nb_rdv_simultanes_for(date_obj)
    return [] unless capacity.positive?

    # Récupère tous les meetings de la journée (chevauchement avec la plage 00h–23h59).
    meetings_du_jour = Meeting.where.not(datefin: nil)
                              .where("datedebut <= ? AND datefin >= ?",
                                     date_obj.end_of_day,
                                     date_obj.beginning_of_day)
    return [] if meetings_du_jour.empty?

    # Durée de fenêtre de vérification : 60 min (durée maximale supposée d'un RDV de base).
    fenetre = 60.minutes

    creneaux_horaires_pour_date(date_obj).select do |heure|
      debut = Time.zone.parse("#{date_obj} #{heure}")
      fin   = debut + fenetre

      # Nombre de meetings qui chevauchent ce créneau.
      chevauchements = meetings_du_jour.count { |m| debut < m.datefin && fin > m.datedebut }
      chevauchements >= capacity
    end
  end

  # Créneaux occupés pour les <days_ahead> prochains jours.
  # Retourne un Hash { "YYYY-MM-DD" => ["HH:MM", …] } (seules les dates avec des créneaux occupés).
  def self.creneaux_occupes_par_date(days_ahead: 90)
    (Date.today..(Date.today + days_ahead)).each_with_object({}) do |date, result|
      occupes = creneaux_occupes_pour_date(date)
      result[date.strftime("%Y-%m-%d")] = occupes if occupes.any?
    end
  end

  # Créneaux encore disponibles pour une date donnée.
  def self.creneaux_disponibles_pour_date(date)
    creneaux_horaires_pour_date(date) - creneaux_occupes_pour_date(date)
  end

  # ---- Méthodes de classe pour le calendrier -----------------------------

  # Numéros de jours de la semaine (wday Ruby : 0=dim … 6=sam) dont la capacité est 0.
  # Utilisé par le calendrier JS pour désactiver ces jours.
  def self.jours_desactives
    config = ParametreRdv.current
    return [] unless config

    ParametreRdv::DAY_SYMBOLS.each_with_index.filter_map do |day_sym, wday|
      wday if (config.public_send(:"nb_rdv_simultanes_#{day_sym}") || 0) == 0
    end
  end

  # Périodes non disponibles (dates exclues dans le calendrier).
  # Format : Array de { debut: "YYYY-MM-DD", fin: "YYYY-MM-DD" }.
  # Les périodes récurrentes sont projetées sur l'année courante et la suivante.
  def self.periodes_non_disponibles
    today        = Date.today
    current_year = today.year

    PeriodeNonDisponible.all.flat_map do |periode|
      if periode.recurrence
        [current_year, current_year + 1].map do |year|
          {
            debut: Date.new(year, periode.date_debut.month, periode.date_debut.day).strftime("%Y-%m-%d"),
            fin:   Date.new(year, periode.date_fin.month,   periode.date_fin.day).strftime("%Y-%m-%d")
          }
        end
      else
        { debut: periode.date_debut.strftime("%Y-%m-%d"), fin: periode.date_fin.strftime("%Y-%m-%d") }
      end
    end
  end

  private

  # Vérifie que type_rdv correspond à un TypeRdv existant.
  def type_rdv_must_be_valid
    return if type_rdv.blank?
    return if TypeRdv.exists?(code: type_rdv)

    errors.add(:type_rdv, "n'est pas un type de rendez-vous valide")
  end

  # ---- Synchronisation Meeting -------------------------------------------

  # Maintient la cohérence entre le statut de la demande et le meeting associé :
  #   - "confirmé"  → crée ou met à jour le meeting
  #   - autre statut → supprime le meeting s'il existe
  def sync_meeting_with_statut
    if statut == "confirmé"
      create_or_update_meeting
    else
      destroy_meeting_if_exists
    end
  end

  def create_or_update_meeting
    return unless date_rdv.present?

    client, _created = Client.create_from_demande(self)
    return unless client&.persisted?

    datedebut = date_rdv
    datefin   = datedebut + duree_rdv_minutes.minutes

    attrs = { nom: "RDV depuis site", datedebut: datedebut, datefin: datefin,
              lieu: "boutique", client_id: client.id }

    if meeting.present?
      meeting.update(attrs)
    else
      create_meeting(attrs.merge(demande_rdv_id: id))
    end
  end

  def destroy_meeting_if_exists
    meeting&.destroy
  end
end
