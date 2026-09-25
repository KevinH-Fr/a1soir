# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public::DemandeRdv", type: :request do
  let!(:type_rdv) { TypeRdv.create!(code: "Découverte req", duree_base_minutes: 60) }

  def post_demande(locale)
    post "/#{locale}/rdv/reservation", params: {
      "g-recaptcha-response" => "ok",
      demande_rdv: {
        prenom: "Jane",
        nom: "Doe",
        email: "visite-#{locale}@example.com",
        telephone: "0600000002",
        date_rdv: 3.days.from_now.change(hour: 11, min: 0).iso8601,
        type_rdv: type_rdv.code,
        nombre_personnes: 1,
        evenement: "mariage",
        date_evenement: 1.month.from_now.to_date.to_s,
        commentaire: "Depuis le site"
      }
    }
  end

  before do
    allow(RecaptchaVerifier).to receive(:verify).and_return(true)
  end

  it "enregistre la locale EN de la page sur la demande" do
    post_demande("en")

    demande = DemandeRdv.find_by(email: "visite-en@example.com")
    expect(demande).to be_present
    expect(demande.locale).to eq("en")
    expect(response).to redirect_to("/en/rdv")
  end

  it "enregistre la locale FR de la page sur la demande" do
    post_demande("fr")

    demande = DemandeRdv.find_by(email: "visite-fr@example.com")
    expect(demande.locale).to eq("fr")
  end
end
