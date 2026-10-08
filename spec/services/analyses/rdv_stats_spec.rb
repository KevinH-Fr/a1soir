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

  it "groups received demandes by statut and type" do
    create_demande(statut: "soumis", type_rdv: type_decouverte.code)
    create_demande(
      email: "conf-#{SecureRandom.hex(3)}@test.com",
      statut: "confirmé",
      type_rdv: type_essayage.code
    )
    create_demande(
      email: "ann-#{SecureRandom.hex(3)}@test.com",
      statut: "annulé",
      type_rdv: type_essayage.code
    )

    stats = described_class.call(debut: debut, fin: fin)

    expect(stats[:by_statut]).to eq("soumis" => 1, "confirmé" => 1, "annulé" => 1)
    expect(stats[:by_type][type_essayage.code]).to eq(2)
    expect(stats[:by_type][type_decouverte.code]).to eq(1)
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
    expect(heatmap[:hours]).to include(10, 14)
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

  describe "transformation rate" do
    it "counts confirmed demandes with a hors-devis commande after meeting.created_at" do
      demande = create_demande(statut: "soumis")
      meeting = confirm!(demande)
      create_commande_for(meeting.client, created_at: meeting.created_at + 1.day)

      stats = described_class.call(debut: debut, fin: fin)

      expect(stats[:confirmes]).to eq(1)
      expect(stats[:transformees]).to eq(1)
      expect(stats[:taux_transformation]).to eq(100.0)
    end

    it "ignores commandes created before confirmation" do
      demande = create_demande(statut: "soumis")
      meeting = confirm!(demande)
      create_commande_for(meeting.client, created_at: meeting.created_at - 1.day)

      stats = described_class.call(debut: debut, fin: fin)

      expect(stats[:confirmes]).to eq(1)
      expect(stats[:transformees]).to eq(0)
      expect(stats[:taux_transformation]).to eq(0.0)
    end

    it "ignores devis and non-confirmed demandes" do
      confirmed = create_demande(statut: "soumis")
      meeting = confirm!(confirmed)
      create_commande_for(meeting.client, created_at: meeting.created_at + 1.hour, devis: true)

      soumis = create_demande(email: "soumis-#{SecureRandom.hex(3)}@test.com", statut: "soumis")
      client = Client.create!(
        prenom: soumis.prenom,
        nom: soumis.nom,
        mail: soumis.email,
        tel: soumis.telephone,
        propart: "particulier",
        intitule: Client::INTITULE_OPTIONS.first
      )
      create_commande_for(client, created_at: Time.zone.local(2026, 9, 20, 12, 0, 0))

      stats = described_class.call(debut: debut, fin: fin)

      expect(stats[:confirmes]).to eq(1)
      expect(stats[:transformees]).to eq(0)
      expect(stats[:taux_transformation]).to eq(0.0)
    end

    it "returns nil taux when there are no confirmed demandes" do
      create_demande(statut: "soumis")

      stats = described_class.call(debut: debut, fin: fin)

      expect(stats[:confirmes]).to eq(0)
      expect(stats[:taux_transformation]).to be_nil
    end
  end
end
