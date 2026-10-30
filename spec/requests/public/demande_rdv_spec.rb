# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public::DemandeRdv", type: :request do
  let!(:type_rdv) { TypeRdv.create!(code: "Découverte req", duree_base_minutes: 60) }

  def post_demande(locale, extra_params = {})
    post "/#{locale}/rdv/reservation", params: extra_params.merge(
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
    )
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

  describe "notification admin" do
    it "est envoyée une fois pour un rendez-vous simple" do
      expect { post_demande("fr") }
        .to have_enqueued_mail(DemandeRdvMailer, :notification_admin).once
    end

    it "est envoyée une fois pour une demande cabine, cabine déjà enregistrée" do
      produit = Produit.create!(
        nom: "Robe cabine",
        prixvente: 50,
        eshop: true,
        today_availability: true,
        quantite: 1
      )
      post "/fr/cabine/add_product/#{produit.id}",
           headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

      expect { post_demande("fr", "from_cabine" => "1") }
        .to have_enqueued_mail(DemandeRdvMailer, :notification_admin).once

      demande = DemandeRdv.find_by(email: "visite-fr@example.com")
      expect(demande.demande_cabine_essayage.produits).to contain_exactly(produit)
    end
  end

  describe "événement GA4 request_appointment" do
    let(:event_attr) { 'data-ga4-event-event-name-value="request_appointment"' }

    before { cookies[:analytics_consent] = "yes" }

    it "est rendu une seule fois après une demande enregistrée" do
      post_demande("fr")
      follow_redirect!

      expect(response.body).to include(event_attr)
      expect(response.body).to include('data-ga4-event-meta-event-name-value="Schedule"')
      expect(response.body).to include('data-ga4-event-tiktok-event-name-value="Schedule"')
      expect(response.body).to include("Rendez-vous boutique")
      expect(response.body).to include("appointment")
      expect(response.body).not_to include("visite-fr@example.com")

      get "/fr/rdv"
      expect(response.body).not_to include(event_attr)
      expect(response.body).not_to include('data-ga4-event-meta-event-name-value="Schedule"')
      expect(response.body).not_to include('data-ga4-event-tiktok-event-name-value="Schedule"')
    end

    it "envoie Schedule pour une demande cabine" do
      produit = Produit.create!(
        nom: "Robe cabine meta",
        prixvente: 50,
        eshop: true,
        today_availability: true,
        quantite: 1
      )
      post "/fr/cabine/add_product/#{produit.id}",
           headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

      post_demande("fr", "from_cabine" => "1")
      follow_redirect!

      expect(response.body).to include(event_attr)
      expect(response.body).to include('data-ga4-event-meta-event-name-value="Schedule"')
      expect(response.body).to include('data-ga4-event-tiktok-event-name-value="Schedule"')
      expect(response.body).to include("Rendez-vous boutique")

      get "/fr/cabine_essayage"
      expect(response.body).not_to include(event_attr)
      expect(response.body).not_to include('data-ga4-event-meta-event-name-value="Schedule"')
      expect(response.body).not_to include('data-ga4-event-tiktok-event-name-value="Schedule"')
    end

    it "n'est pas rendu si la demande est invalide" do
      post "/fr/rdv/reservation", params: {
        "g-recaptcha-response" => "ok",
        demande_rdv: { nom: "", email: "" }
      }

      get "/fr/rdv"
      expect(response.body).not_to include(event_attr)
    end

    it "n'est pas rendu sans consentement analytics" do
      cookies[:analytics_consent] = "no"

      post_demande("fr")
      follow_redirect!

      expect(response.body).not_to include(event_attr)
    end
  end
end
