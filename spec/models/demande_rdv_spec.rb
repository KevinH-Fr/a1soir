# frozen_string_literal: true

require "rails_helper"

RSpec.describe DemandeRdv, type: :model do
  let!(:type_rdv) { TypeRdv.create!(code: "Découverte spec", duree_base_minutes: 60) }

  def build_demande(attrs = {})
    described_class.new({
      prenom: "Jane",
      nom: "Doe",
      email: "jane.doe@example.com",
      telephone: "0600000000",
      date_rdv: 3.days.from_now.change(hour: 10, min: 0),
      type_rdv: type_rdv.code,
      nombre_personnes: 1,
      evenement: "mariage",
      date_evenement: 1.month.from_now.to_date,
      statut: "soumis",
      locale: "en"
    }.merge(attrs))
  end

  describe "locale de la visite" do
    it "retombe sur fr si la locale est absente" do
      demande = build_demande(locale: nil)
      demande.valid?

      expect(demande.locale).to eq("fr")
    end

    it "écrit la locale sur une nouvelle fiche, puis le rappel de RDV part dans cette langue" do
      calendar = instance_double(
        GoogleCalendarService,
        create_event_from_meeting: "evt-test",
        update_event_from_meeting: true,
        delete_event: true
      )
      allow(GoogleCalendarService).to receive(:new).and_return(calendar)
      ActionMailer::Base.deliveries.clear

      demande = build_demande(email: "nouvelle-en@example.com", locale: "en")
      demande.save!
      demande.update!(statut: "confirmé")

      client = Client.find_by(mail: "nouvelle-en@example.com")
      expect(client.language).to eq("en")

      reminder = ActionMailer::Base.deliveries.last
      expect(reminder.to).to eq(["nouvelle-en@example.com"])
      expect(reminder.subject).to eq(I18n.t("reminders.subject", locale: :en))
    end

    it "ne change pas la langue d'une fiche déjà existante" do
      existing = Client.create!(
        prenom: "Jane",
        nom: "Doe",
        mail: "deja-la@example.com",
        tel: "0600000000",
        language: "fr",
        propart: "particulier",
        intitule: Client::INTITULE_OPTIONS.first
      )

      calendar = instance_double(
        GoogleCalendarService,
        create_event_from_meeting: "evt-test",
        update_event_from_meeting: true,
        delete_event: true
      )
      allow(GoogleCalendarService).to receive(:new).and_return(calendar)

      demande = build_demande(email: "deja-la@example.com", nom: "Doe", prenom: "Jane", locale: "en")
      demande.save!
      demande.update!(statut: "confirmé")

      expect(existing.reload.language).to eq("fr")
      expect(demande.client_mail_locale).to eq(:fr)
    end
  end
end
