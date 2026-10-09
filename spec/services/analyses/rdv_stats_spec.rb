# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::RdvStats do
  let!(:type_decouverte) { TypeRdv.create!(code: "Découverte rdv stats", duree_base_minutes: 60) }
  let!(:type_essayage) { TypeRdv.create!(code: "Essayage rdv stats", duree_base_minutes: 45) }

  let(:debut) { Time.zone.local(2026, 9, 1) }
  let(:fin) { Time.zone.local(2026, 9, 30) }

  before do
    calendar = instance_double(
      GoogleCalendarService,
      create_event_from_meeting: "evt-test",
      update_event_from_meeting: true,
      delete_event: true
    )
    allow(GoogleCalendarService).to receive(:new).and_return(calendar)
    allow(MeetingMailer).to receive_message_chain(:reminder_email, :deliver_now)
  end

  def create_demande(attrs = {})
    DemandeRdv.create!({
      prenom: "Ada",
      nom: "Lovelace",
      email: "rdv-stats-#{SecureRandom.hex(4)}@test.com",
      telephone: "0600000000",
      date_rdv: Time.zone.local(2026, 9, 15, 10, 0, 0),
      type_rdv: type_decouverte.code,
      nombre_personnes: 1,
      evenement: "mariage",
      date_evenement: Date.new(2026, 12, 1),
      statut: "soumis",
      locale: "fr",
      created_at: Time.zone.local(2026, 9, 10, 11, 0, 0)
    }.merge(attrs))
  end

  def attach_cabine!(demande)
    cabine = DemandeCabineEssayage.new(demande_rdv: demande)
    cabine.save!(validate: false)
    cabine
  end

  def confirm!(demande)
    demande.update!(statut: "confirmé")
    demande.meeting
  end

  def create_commande_for(client, created_at:, devis: false)
    allow(GenerateQr).to receive(:call) if defined?(GenerateQr)
    profile = Profile.first || Profile.create!(prenom: "Vendeur", nom: "Rdv")
    Commande.create!(
      client: client,
      profile: profile,
      nom: "Cmd rdv #{SecureRandom.hex(3)}",
      montant: 100,
      devis: devis,
      type_locvente: "vente",
      typeevent: Commande::EVENEMENTS_OPTIONS.first,
      created_at: created_at
    )
  end

  def create_interne_meeting!(datedebut:)
    client = Client.create!(
      prenom: "Interne",
      nom: "Agenda#{SecureRandom.hex(2)}",
      mail: "interne-#{SecureRandom.hex(3)}@test.com",
      tel: "0600000000",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first
    )
    Meeting.create!(
      nom: "RDV interne seed",
      datedebut: datedebut,
      datefin: datedebut + 1.hour,
      lieu: "boutique",
      client: client
    )
  end

  it "counts site demandes by created_at and cabine share" do
    create_demande(
      created_at: Time.zone.local(2026, 9, 5, 9, 0, 0),
      date_rdv: Time.zone.local(2026, 10, 5, 10, 0, 0)
    )
    create_demande(
      created_at: Time.zone.local(2026, 8, 20, 9, 0, 0),
      date_rdv: Time.zone.local(2026, 9, 20, 10, 0, 0)
    )
    avec = create_demande(created_at: Time.zone.local(2026, 9, 12, 9, 0, 0))
    attach_cabine!(avec)

    stats = described_class.call(debut: debut, fin: fin)

    expect(stats[:demandes_recues]).to eq(2)
    expect(stats[:avec_cabine]).to eq(1)
    expect(stats[:sans_cabine]).to eq(1)
    expect(stats[:part_cabine]).to eq(50.0)
  end

  it "groups received demandes by statut, type and événement" do
    create_demande(statut: "soumis", type_rdv: type_decouverte.code, evenement: "mariage")
    create_demande(
      email: "conf-#{SecureRandom.hex(3)}@test.com",
      statut: "confirmé",
      type_rdv: type_essayage.code,
      evenement: "soiree"
    )
    create_demande(
      email: "ann-#{SecureRandom.hex(3)}@test.com",
      statut: "annulé",
      type_rdv: type_essayage.code,
      evenement: "soiree"
    )

    stats = described_class.call(debut: debut, fin: fin)

    expect(stats[:by_statut]).to eq("soumis" => 1, "confirmé" => 1, "annulé" => 1)
    expect(stats[:by_type][type_essayage.code]).to eq(2)
    expect(stats[:by_type][type_decouverte.code]).to eq(1)
    expect(stats[:by_evenement]["Soirée"]).to eq(2)
    expect(stats[:by_evenement]["Mariage"]).to eq(1)
  end

  it "builds demande heatmap by weekday and hour of created_at" do
    # 2026-09-07 = lundi (wday 1)
    create_demande(created_at: Time.zone.local(2026, 9, 7, 10, 30, 0))
    create_demande(
      email: "heat-#{SecureRandom.hex(3)}@test.com",
      created_at: Time.zone.local(2026, 9, 7, 10, 45, 0)
    )
    create_demande(
      email: "heat2-#{SecureRandom.hex(3)}@test.com",
      created_at: Time.zone.local(2026, 9, 8, 14, 0, 0) # mardi
    )

    stats = described_class.call(debut: debut, fin: fin)
    heatmap = stats[:demande_heatmap]

    expect(heatmap[:counts][[1, 10]]).to eq(2)
    expect(heatmap[:counts][[2, 14]]).to eq(1)
    expect(heatmap[:max]).to eq(2)
    expect(heatmap[:hours]).to eq((0..23).to_a)
  end

  it "splits agenda meetings between site and interne" do
    demande = create_demande(statut: "soumis")
    confirm!(demande)
    create_interne_meeting!(datedebut: Time.zone.local(2026, 9, 18, 14, 0, 0))
    create_interne_meeting!(datedebut: Time.zone.local(2026, 10, 2, 14, 0, 0)) # hors période

    stats = described_class.call(debut: debut, fin: fin)

    expect(stats[:agenda_site]).to eq(1)
    expect(stats[:agenda_interne]).to eq(1)
    expect(stats[:agenda_total]).to eq(2)
  end

  describe "transformation pending window" do
    # « Aujourd'hui » au 25 septembre : le RDV du 20 est < 14 j, celui du 5 est ≥ 14 j.
    around do |example|
      travel_to(Time.zone.local(2026, 9, 25, 12, 0, 0)) { example.run }
    end

    it "splits RDV without commande into en cours (< 14 j) and sans (≥ 14 j)" do
      recent = create_demande(
        email: "recent-#{SecureRandom.hex(3)}@test.com",
        statut: "soumis",
        date_rdv: Time.zone.local(2026, 9, 20, 10, 0, 0)
      )
      confirm!(recent)

      old = create_demande(
        email: "old-#{SecureRandom.hex(3)}@test.com",
        statut: "soumis",
        date_rdv: Time.zone.local(2026, 9, 5, 10, 0, 0)
      )
      confirm!(old)

      stats = described_class.call(debut: debut, fin: fin)

      expect(stats[:confirmes]).to eq(2)
      expect(stats[:transformees]).to eq(0)
      expect(stats[:transformation_en_cours]).to eq(1)
      expect(stats[:transformation_sans]).to eq(1)
    end
  end

  describe "transformation rate" do
    # RDV de septembre : ≥ 14 j → « sans » si pas de commande.
    around do |example|
      travel_to(Time.zone.local(2026, 10, 5, 12, 0, 0)) { example.run }
    end

    it "counts site RDV in the period with a hors-devis commande also in the period" do
      demande = create_demande(statut: "soumis", date_rdv: Time.zone.local(2026, 9, 15, 10, 0, 0))
      meeting = confirm!(demande)
      create_commande_for(meeting.client, created_at: Time.zone.local(2026, 9, 20, 12, 0, 0))

      stats = described_class.call(debut: debut, fin: fin)

      expect(stats[:confirmes]).to eq(1)
      expect(stats[:transformees]).to eq(1)
      expect(stats[:transformation_en_cours]).to eq(0)
      expect(stats[:transformation_sans]).to eq(0)
      expect(stats[:taux_transformation]).to eq(100.0)
    end

    it "ignores commandes before the RDV or outside the period and counts them as sans" do
      early = create_demande(
        email: "early-#{SecureRandom.hex(3)}@test.com",
        statut: "soumis",
        date_rdv: Time.zone.local(2026, 9, 10, 10, 0, 0)
      )
      early_meeting = confirm!(early)
      create_commande_for(early_meeting.client, created_at: early_meeting.datedebut - 1.day)

      late = create_demande(
        email: "late-#{SecureRandom.hex(3)}@test.com",
        statut: "soumis",
        date_rdv: Time.zone.local(2026, 9, 12, 10, 0, 0)
      )
      late_meeting = confirm!(late)
      create_commande_for(late_meeting.client, created_at: Time.zone.local(2026, 10, 5, 12, 0, 0))

      stats = described_class.call(debut: debut, fin: fin)

      expect(stats[:confirmes]).to eq(2)
      expect(stats[:transformees]).to eq(0)
      expect(stats[:transformation_en_cours]).to eq(0)
      expect(stats[:transformation_sans]).to eq(2)
      expect(stats[:taux_transformation]).to eq(0.0)
    end

    it "sums encaissements of linked commandes once, ignoring caution, devis and refunds" do
      demande = create_demande(
        email: "ca-#{SecureRandom.hex(3)}@test.com",
        statut: "soumis",
        date_rdv: Time.zone.local(2026, 9, 10, 10, 0, 0)
      )
      meeting = confirm!(demande)
      autre = create_demande(
        email: "ca2-#{SecureRandom.hex(3)}@test.com",
        statut: "confirmé",
        date_rdv: Time.zone.local(2026, 9, 12, 11, 0, 0)
      )
      Meeting.create!(
        nom: "Second RDV site",
        datedebut: autre.date_rdv,
        datefin: autre.date_rdv + 1.hour,
        lieu: "boutique",
        client: meeting.client,
        demande_rdv: autre
      )

      commande = create_commande_for(meeting.client, created_at: Time.zone.local(2026, 9, 20, 12, 0, 0))
      PaiementRecu.create!(commande: commande, typepaiement: "prix", montant: 80, moyen: "carte bleue")
      PaiementRecu.create!(commande: commande, typepaiement: "caution", montant: 200, moyen: "espèces")
      PaiementRecu.create!(commande: commande, typepaiement: "prix", montant: 40, moyen: "espèces")
      StripePayment.create!(
        commande: commande,
        stripe_payment_id: "sp_rdv_#{SecureRandom.hex(4)}",
        amount: 2_500,
        currency: "eur",
        status: "paid"
      )
      AvoirRemb.create!(
        commande: commande,
        type_avoir_remb: "remboursement",
        montant: 15,
        moyen: "carte bleue"
      )
      create_commande_for(meeting.client, created_at: Time.zone.local(2026, 9, 22, 12, 0, 0), devis: true)

      stats = described_class.call(debut: debut, fin: fin)

      expect(stats[:transformees]).to eq(2)
      expect(stats[:ca_transformees]).to eq(130)
    end

    it "ignores devis and interne meetings" do
      site = create_demande(
        email: "site-#{SecureRandom.hex(3)}@test.com",
        statut: "soumis",
        date_rdv: Time.zone.local(2026, 9, 15, 10, 0, 0)
      )
      site_meeting = confirm!(site)
      create_commande_for(site_meeting.client, created_at: Time.zone.local(2026, 9, 16, 12, 0, 0), devis: true)

      interne = create_interne_meeting!(datedebut: Time.zone.local(2026, 9, 18, 14, 0, 0))
      create_commande_for(interne.client, created_at: Time.zone.local(2026, 9, 19, 12, 0, 0))

      stats = described_class.call(debut: debut, fin: fin)

      expect(stats[:confirmes]).to eq(1)
      expect(stats[:transformees]).to eq(0)
      expect(stats[:transformation_sans]).to eq(1)
      expect(stats[:taux_transformation]).to eq(0.0)
    end

    it "returns nil taux when there are no site RDV with client in the period" do
      create_demande(statut: "soumis")

      stats = described_class.call(debut: debut, fin: fin)

      expect(stats[:confirmes]).to eq(0)
      expect(stats[:taux_transformation]).to be_nil
    end
  end
end
