# frozen_string_literal: true

require "rails_helper"

RSpec.describe DemandeRdvMailer, type: :mailer do
  def build_demande(attrs = {})
    DemandeRdv.new({
      prenom: "Jane",
      nom: "Doe",
      email: "jane.doe@example.com",
      telephone: "0600000000",
      locale: "en"
    }.merge(attrs))
  end

  describe "#confirmation_client" do
    it "utilise la locale de la visite quand aucune fiche n'existe encore" do
      mail = described_class.confirmation_client(build_demande(locale: "en"))

      expect(mail.subject).to eq(I18n.t("demande_rdv.confirmation_client.subject", locale: :en))
      expect(mail.html_part.body.decoded).to include("Hello Jane,")
    end

    it "utilise la langue déjà enregistrée sur la fiche client" do
      Client.create!(
        prenom: "Jane",
        nom: "Doe",
        mail: "fiche-fr@example.com",
        tel: "0600000000",
        language: "fr",
        propart: "particulier",
        intitule: Client::INTITULE_OPTIONS.first
      )

      mail = described_class.confirmation_client(
        build_demande(email: "fiche-fr@example.com", locale: "en")
      )

      expect(mail.subject).to eq(I18n.t("demande_rdv.confirmation_client.subject", locale: :fr))
      expect(mail.html_part.body.decoded).to include("Bonjour Jane,")
    end
  end

  describe "#notification_admin" do
    it "reste en français" do
      previous = ENV["GMAIL_ACCOUNT"]
      ENV["GMAIL_ACCOUNT"] = "admin@example.com"

      mail = described_class.notification_admin(build_demande(locale: "en"))

      expect(mail.subject).to eq(I18n.t("demande_rdv.notification_admin.subject", locale: :fr))
    ensure
      ENV["GMAIL_ACCOUNT"] = previous
    end
  end
end
