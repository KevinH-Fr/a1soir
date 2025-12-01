class ParametreRdv < ApplicationRecord
  validates :minutes_par_personne_supp,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Renvoie la configuration "courante".
  # Pour l'instant on prend la plus récente, ou nil si rien n'existe.
  def self.current
    order(created_at: :desc).first
  end

  # -------- Créneaux horaires --------

  # Retourne un Array de strings ["10:00", "11:00", ...]
  def creneaux_horaires_list
    (creneaux_horaires || "")
      .split(",")
      .map(&:strip)
      .reject(&:blank?)
  end

  # Permet d'assigner via un Array et sérialise en string "10:00,11:00"
  def creneaux_horaires_list=(values)
    self.creneaux_horaires = Array(values)
      .map(&:to_s)
      .map(&:strip)
      .reject(&:blank?)
      .join(",")
  end

  # -------- Capacité par jour de semaine --------

  # Retourne le nombre de RDV simultanés max pour une date donnée.
  # Utilise wday de la date (0..6, dimanche..samedi) et mappe sur les colonnes.
  def nb_rdv_simultanes_for(date)
    date = date.to_date
    # En Ruby : 0 = dimanche, 1 = lundi, ..., 6 = samedi
    case date.wday
    when 1
      nb_rdv_simultanes_lundi || 0
    when 2
      nb_rdv_simultanes_mardi || 0
    when 3
      nb_rdv_simultanes_mercredi || 0
    when 4
      nb_rdv_simultanes_jeudi || 0
    when 5
      nb_rdv_simultanes_vendredi || 0
    when 6
      nb_rdv_simultanes_samedi || 0
    when 0
      nb_rdv_simultanes_dimanche || 0
    else
      0
    end
  end
end


