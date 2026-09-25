# frozen_string_literal: true

# Client technique partagé pour les ventes créées via « Vente rapide ».
module ClientCommandeRapide
  extend ActiveSupport::Concern

  COMMANDE_RAPIDE_PRENOM = "Vente"
  COMMANDE_RAPIDE_NOM = "Rapide"
  COMMANDE_RAPIDE_PRENOM_LEGACY = "Commande"
  COMMANDE_RAPIDE_TEL = "0000000000"
  # Domaine réservé RFC (`.invalid`) : non livrable, pas un faux domaine métier.
  COMMANDE_RAPIDE_MAIL = "commande-rapide@example.invalid"
  COMMANDE_RAPIDE_MAIL_LEGACY = "commande.rapide@interne.a1soir.local"

  class_methods do
    # Find-or-create + normalisation douce (mail / prénom legacy → attrs techniques).
    def commande_rapide
      client = find_commande_rapide_record
      return sync_commande_rapide_attrs!(client) if client

      create!(
        prenom: ClientCommandeRapide::COMMANDE_RAPIDE_PRENOM,
        nom: ClientCommandeRapide::COMMANDE_RAPIDE_NOM,
        tel: ClientCommandeRapide::COMMANDE_RAPIDE_TEL,
        mail: ClientCommandeRapide::COMMANDE_RAPIDE_MAIL,
        propart: "particulier",
        intitule: Client::INTITULE_OPTIONS.first
      )
    end

    # Lookup sans création (scopes, badges).
    def commande_rapide_id
      find_commande_rapide_record&.id
    end

    private

    def find_commande_rapide_record
      find_by(
        prenom: ClientCommandeRapide::COMMANDE_RAPIDE_PRENOM,
        nom: ClientCommandeRapide::COMMANDE_RAPIDE_NOM
      ) ||
        find_by(
          prenom: ClientCommandeRapide::COMMANDE_RAPIDE_PRENOM_LEGACY,
          nom: ClientCommandeRapide::COMMANDE_RAPIDE_NOM
        ) ||
        find_by(mail: ClientCommandeRapide::COMMANDE_RAPIDE_MAIL) ||
        find_by(mail: ClientCommandeRapide::COMMANDE_RAPIDE_MAIL_LEGACY)
    end

    def sync_commande_rapide_attrs!(client)
      attrs = {}
      attrs[:mail] = ClientCommandeRapide::COMMANDE_RAPIDE_MAIL if client.mail != ClientCommandeRapide::COMMANDE_RAPIDE_MAIL
      attrs[:tel] = ClientCommandeRapide::COMMANDE_RAPIDE_TEL if client.tel != ClientCommandeRapide::COMMANDE_RAPIDE_TEL
      attrs[:prenom] = ClientCommandeRapide::COMMANDE_RAPIDE_PRENOM if client.prenom != ClientCommandeRapide::COMMANDE_RAPIDE_PRENOM
      attrs[:nom] = ClientCommandeRapide::COMMANDE_RAPIDE_NOM if client.nom != ClientCommandeRapide::COMMANDE_RAPIDE_NOM
      client.update!(attrs) if attrs.any?
      client
    end
  end

  def commande_rapide?
    nom.to_s.casecmp?(ClientCommandeRapide::COMMANDE_RAPIDE_NOM) &&
      (
        prenom.to_s.casecmp?(ClientCommandeRapide::COMMANDE_RAPIDE_PRENOM) ||
        prenom.to_s.casecmp?(ClientCommandeRapide::COMMANDE_RAPIDE_PRENOM_LEGACY)
      )
  end
end
