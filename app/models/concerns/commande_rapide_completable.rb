# frozen_string_literal: true

# Repérage des commandes encore sur client / profil techniques « Vente rapide ».
module CommandeRapideCompletable
  extend ActiveSupport::Concern

  included do
    scope :a_completer, lambda {
      client_id = Client.commande_rapide_id
      profile_id = Profile.commande_rapide_id

      conditions = []
      conditions << where(client_id: client_id) if client_id
      conditions << where(profile_id: profile_id) if profile_id
      return none if conditions.empty?

      conditions.reduce { |scope, next_scope| scope.or(next_scope) }
    }
  end

  def a_completer?
    client&.commande_rapide? || profile&.commande_rapide?
  end

  def dates_location_manquantes?
    return false if debutloc.present? && finloc.present?

    if association(:articles).loaded?
      articles.any? { |a| a.locvente.to_s == "location" }
    else
      articles.where(locvente: "location").exists?
    end
  end

  def evenement_manquant?
    typeevent.blank? || dateevent.blank?
  end
end
