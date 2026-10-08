# frozen_string_literal: true

Seeds::Helpers.log("07", "RDV et contenu boutique")

[
  ["Découverte", 45],
  ["Essayage", 60],
  ["Retouche", 30]
].each do |code, minutes|
  TypeRdv.find_or_create_by!(code: code) do |t|
    t.duree_base_minutes = minutes
  end
end

unless ParametreRdv.exists?
  creneaux = ParametreRdv::DEFAULT_CRENEAUX.join(",")
  ParametreRdv.create!(
    nom: "Boutique principale",
    minutes_par_personne_supp: 15,
    creneaux_lundi: creneaux,
    creneaux_mardi: creneaux,
    creneaux_mercredi: creneaux,
    creneaux_jeudi: creneaux,
    creneaux_vendredi: creneaux,
    creneaux_samedi: creneaux,
    creneaux_dimanche: ""
  )
end

Texte.find_or_create_by!(titre: "Boutique démo") do |t|
  t.adresse = "1 rue de la Démo, 75000 Paris"
end

# --- Demandes de RDV (site) pour l'onglet Analyses ---------------------------
Seeds::Helpers.log("07", "Demandes de RDV du site (Analyses)")

produit_cabine = Produit.find_by(nom: "Robe cocktail démo") || Produit.order(:id).first
profile_marie = Profile.find_by(prenom: "Marie", nom: "Dupont") || Profile.order(:id).first
raise "Seed RDV : produit ou profil manquant (lancez 02/05/06 avant)" if produit_cabine.blank? || profile_marie.blank?

types = TypeRdv.ordered.pluck(:code)
evenements = %w[mariage soiree autre]
prenoms = %w[Camille Léa Emma Hugo Louis Chloé Inès Noah Jade Arthur Manon Théo]
noms = %w[Petit Roux Moreau Garcia Lefebvre Faure Blanc Guerin Andre Renaud]

# days_ago_created, days_ago_rdv (négatif = RDV à venir, hors période Analyses),
# statut, type_idx, cabine?, transform?
# Étalé sur ~30 j (période Analyses par défaut) ; reçues ≠ prévus volontairement.
rdv_seed_rows = [
  [0,  0,  "soumis",    0, false, false],
  [1,  0,  "soumis",    1, true,  false],
  [1,  1,  "confirmé",  1, true,  true],
  [2,  1,  "confirmé",  0, false, true],
  [3,  2,  "annulé",    0, false, false],
  [4,  3,  "soumis",    2, false, false],
  [5,  2,  "confirmé",  1, true,  true],
  [6,  -4, "soumis",    0, true,  false],   # reçue, RDV futur hors période
  [7,  4,  "confirmé",  2, false, false],
  [8,  5,  "confirmé",  1, true,  true],
  [9,  3,  "soumis",    0, false, false],
  [10, 6,  "annulé",    1, true,  false],
  [11, 7,  "confirmé",  0, false, true],
  [12, -8, "soumis",    1, true,  false],  # reçue, RDV futur hors période
  [14, 8,  "confirmé",  1, false, false],
  [15, 9,  "soumis",    2, false, false],
  [16, 10, "confirmé",  0, true,  true],
  [18, 11, "annulé",    2, false, false],
  [20, 12, "confirmé",  1, true,  true],
  [21, -10,"soumis",    0, false, false],  # reçue, RDV futur hors période
  [22, 14, "confirmé",  0, false, true],
  [24, 15, "soumis",    1, true,  false],
  [26, 18, "confirmé",  1, true,  true],
  [28, 20, "confirmé",  0, false, false],
  [29, 22, "soumis",    2, false, false]
]

Meeting.skip_callback(:create, :after, :add_calendar_event)
Meeting.skip_callback(:create, :after, :send_reminder_email)
Commande.skip_callback(:create, :after, :generate_qr) if Commande.respond_to?(:skip_callback)

begin
  rdv_seed_rows.each_with_index do |(days_ago, rdv_offset, statut, type_idx, with_cabine, transform), index|
    email = Seeds::Helpers.seed_email(format("rdv-seed-%02d", index + 1))
    prenom = prenoms[index % prenoms.length]
    nom = noms[index % noms.length]
    created_at = Seeds::Helpers.demo_timestamp(days_ago, name: email)
    date_rdv = if rdv_offset.negative?
                 (-rdv_offset).days.from_now.in_time_zone.change(hour: 10 + (index % 6), min: 0, sec: 0)
               else
                 # RDV après la demande, dans la fenêtre Analyses quand possible.
                 rdv_days_ago = [rdv_offset, [days_ago - 1, 0].max].min
                 Seeds::Helpers.demo_timestamp(rdv_days_ago, name: "#{email}-rdv")
               end
    type_rdv = types[type_idx % types.length]

    demande = DemandeRdv.find_or_initialize_by(email: email)
    demande.assign_attributes(
      prenom: prenom,
      nom: nom,
      telephone: format("06%08d", 1000_0000 + index),
      date_rdv: date_rdv,
      type_rdv: type_rdv,
      nombre_personnes: 1 + (index % 3),
      evenement: evenements[index % evenements.length],
      date_evenement: (date_rdv.to_date + 60 + index).to_date,
      statut: statut,
      locale: (index.even? ? "fr" : "en"),
      commentaire: "Seed demande RDV site ##{index + 1}"
    )
    demande.save!
    demande.update_columns(created_at: created_at, updated_at: created_at)

    if with_cabine
      cabine = DemandeCabineEssayage.find_or_initialize_by(demande_rdv_id: demande.id)
      if cabine.new_record?
        cabine.demande_cabine_essayage_items.build(produit: produit_cabine)
        cabine.save!
      end
    elsif demande.demande_cabine_essayage.present?
      demande.demande_cabine_essayage.destroy!
    end

    meeting = demande.meeting
    if statut == "confirmé"
      client, = Client.create_from_demande(demande)
      client.save! unless client.persisted?

      meeting_attrs = {
        nom: with_cabine ? "RDV depuis site - cabine d'essayage" : "RDV depuis site",
        datedebut: date_rdv,
        datefin: date_rdv + demande.duree_rdv_minutes.minutes,
        lieu: "boutique",
        client_id: client.id,
        demande_rdv_id: demande.id
      }
      if meeting
        meeting.update!(meeting_attrs.except(:demande_rdv_id))
      else
        meeting = Meeting.create!(meeting_attrs)
      end
      # Instant de confirmation ≈ réception + 1 jour (pour le taux de transformation).
      meeting.update_columns(created_at: created_at + 1.day, updated_at: created_at + 1.day)

      if transform
        Seeds::Helpers.upsert_demo_commande!(
          nom: "Commande seed RDV #{format('%02d', index + 1)}",
          client: client,
          profile: profile_marie,
          days_ago: [days_ago - 2, 0].max,
          type_locvente: "vente",
          statutarticles: "non-retiré",
          articles: [
            { produit: produit_cabine, locvente: "vente", prix: 80, total: 80 }
          ],
          paiements: [
            { typepaiement: "prix", montant: 80, moyen: "carte bleue" }
          ]
        )
        commande = Commande.find_by!(nom: "Commande seed RDV #{format('%02d', index + 1)}")
        # Garantir created_at >= meeting.created_at
        cmd_at = [meeting.reload.created_at + 2.hours, Seeds::Helpers.demo_timestamp([days_ago - 2, 0].max, name: commande.nom)].max
        Seeds::Helpers.touch_commande_timestamps!(commande, at: cmd_at)
      end
    elsif meeting
      meeting.destroy!
    end
  end

  # RDV créés en admin (sans DemandeRdv) pour l’agenda Analyses
  interne_clients = 8.times.map do |i|
    Client.find_or_create_by!(mail: Seeds::Helpers.seed_email(format("rdv-interne-%02d", i + 1))) do |c|
      c.prenom = %w[Nina Paul Sara Marc Léa Tom Eva Max][i]
      c.nom = "Interne"
      c.propart = "particulier"
      c.intitule = Client::INTITULE_OPTIONS.first
      c.tel = format("0610%06d", i + 1)
    end
  end

  interne_clients.each_with_index do |client, i|
    days_ago = [1, 3, 5, 8, 12, 16, 20, 25][i]
    datedebut = Seeds::Helpers.demo_timestamp(days_ago, name: "meeting-interne-#{i}")
    meeting = Meeting.find_or_initialize_by(nom: "RDV interne seed #{format('%02d', i + 1)}")
    meeting.assign_attributes(
      client: client,
      datedebut: datedebut,
      datefin: datedebut + 45.minutes,
      lieu: "boutique",
      demande_rdv_id: nil
    )
    meeting.save!
    meeting.update_columns(created_at: datedebut - 2.days, updated_at: datedebut - 2.days)
  end
ensure
  Meeting.set_callback(:create, :after, :add_calendar_event)
  Meeting.set_callback(:create, :after, :send_reminder_email)
  Commande.set_callback(:create, :after, :generate_qr) if Commande.respond_to?(:set_callback)
end

site_count = DemandeRdv.where("email LIKE ?", "rdv-seed-%@dev.a1soir.local").count
cabine_count = DemandeCabineEssayage.joins(:demande_rdv)
  .where("demande_rdvs.email LIKE ?", "rdv-seed-%@dev.a1soir.local").count
interne_count = Meeting.where("nom LIKE ?", "RDV interne seed %").count
Seeds::Helpers.log(
  "07",
  "Demandes site : #{site_count} (#{cabine_count} cabine) · Agenda internes : #{interne_count}"
)
