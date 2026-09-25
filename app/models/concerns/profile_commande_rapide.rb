# frozen_string_literal: true

# Profil technique pour les ventes créées via « Vente rapide » (même idée que l’e-shop).
module ProfileCommandeRapide
  extend ActiveSupport::Concern

  COMMANDE_RAPIDE_PROFILE_PRENOM = "Rapide"

  class_methods do
    def commande_rapide
      row = pluck(:id, :prenom).find { |_id, p|
        p.to_s.casecmp?(ProfileCommandeRapide::COMMANDE_RAPIDE_PROFILE_PRENOM)
      }
      return find(row.first) if row

      create!(prenom: ProfileCommandeRapide::COMMANDE_RAPIDE_PROFILE_PRENOM, nom: nil)
    end

    def commande_rapide_id
      row = pluck(:id, :prenom).find { |_id, p|
        p.to_s.casecmp?(ProfileCommandeRapide::COMMANDE_RAPIDE_PROFILE_PRENOM)
      }
      row&.first
    end
  end

  def commande_rapide?
    prenom.to_s.casecmp?(ProfileCommandeRapide::COMMANDE_RAPIDE_PROFILE_PRENOM)
  end
end
