class ParametreRdv < ApplicationRecord
  validates :minutes_par_personne_supp,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Colonnes DB qui stockent les créneaux horaires de chaque jour (CSV en base).
  CRENEAUX_COLUMNS = %i[
    creneaux_lundi
    creneaux_mardi
    creneaux_mercredi
    creneaux_jeudi
    creneaux_vendredi
    creneaux_samedi
    creneaux_dimanche
  ].freeze

  # Labels des jours pour les formulaires et affichages (ordre lundi → dimanche).
  DAY_LABELS = {
    lundi:    "Lundi",
    mardi:    "Mardi",
    mercredi: "Mercredi",
    jeudi:    "Jeudi",
    vendredi: "Vendredi",
    samedi:   "Samedi",
    dimanche: "Dimanche"
  }.freeze

  # Mapping wday Ruby (0 = dimanche … 6 = samedi) → symbole du jour.
  # Utilisé pour convertir Date#wday en nom de colonne.
  DAY_SYMBOLS = %i[dimanche lundi mardi mercredi jeudi vendredi samedi].freeze

  # Créneaux possibles par défaut : toutes les 30 min de 10h à 19h30.
  DEFAULT_CRENEAUX = %w[
    10:00 10:30
    11:00 11:30
    12:00 12:30
    13:00 13:30
    14:00 14:30
    15:00 15:30
    16:00 16:30
    17:00 17:30
    18:00 18:30
    19:00 19:30
  ].freeze

  before_validation :normalize_creneaux_columns

  # Renvoie la configuration courante (la plus récente), ou nil si aucune.
  def self.current
    order(created_at: :desc).first
  end

  # ---- Créneaux horaires par jour ----------------------------------------

  # Retourne les créneaux (Array de "HH:MM") pour :
  #   - une Date / Time / DateTime
  #   - ou un symbole de jour (:lundi, :mardi, …)
  def creneaux_for(day_or_date)
    day_sym =
      case day_or_date
      when Date, Time, DateTime then DAY_SYMBOLS[day_or_date.to_date.wday]
      else day_or_date.to_sym
      end

    parse_creneaux(public_send(:"creneaux_#{day_sym}"))
  end

  # ---- Capacité par jour -------------------------------------------------

  # Retourne le nombre de RDV simultanés autorisés pour la date donnée.
  # Renvoie 0 si non configuré.
  def nb_rdv_simultanes_for(date)
    day_sym = DAY_SYMBOLS[date.to_date.wday]
    public_send(:"nb_rdv_simultanes_#{day_sym}") || 0
  end

  private

  # Parse une valeur stockée en DB (CSV "10:00,10:30,…" ou Array) en Array de strings.
  def parse_creneaux(value)
    return [] if value.blank?

    value.to_s.tr('[]"', "").split(",").map(&:strip).reject(&:blank?)
  end

  # Avant validation : convertit les colonnes créneaux en CSV si elles arrivent sous forme d'Array
  # (cas du formulaire multiselect qui envoie params comme Array).
  def normalize_creneaux_columns
    CRENEAUX_COLUMNS.each do |column|
      values = read_attribute(column)
      next unless values.is_a?(Array)

      write_attribute(
        column,
        values.map(&:to_s).map(&:strip).reject(&:blank?).join(",")
      )
    end
  end
end
