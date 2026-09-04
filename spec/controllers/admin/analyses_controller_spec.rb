# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AnalysesController, type: :controller do
  let(:client) do
    Client.create!(
      nom: "Analyse",
      prenom: "CA",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "analyses-#{SecureRandom.hex(4)}@test.com"
    )
  end

  let(:profile) { Profile.create!(prenom: "Vendeur", nom: "CA") }

  before do
    @request.host = "admin.lvh.me"
    allow(controller).to receive(:authenticate_vendeur_or_admin!).and_return(true)
    allow(controller).to receive(:current_admin_user).and_return(
      instance_double(User, admin?: true, vendeur?: false)
    )
  end

  describe "GET #index" do
    it "nets Stripe CA by eshop remboursements" do
      commande = Commande.create!(
        client: client,
        profile: profile,
        nom: "E-shop CA",
        montant: 65,
        devis: false,
        type_locvente: "vente",
        eshop: true
      )
      StripePayment.create!(
        commande: commande,
        stripe_payment_id: "pi_ca_#{SecureRandom.hex(6)}",
        amount: 6500,
        currency: "eur",
        status: "paid"
      )
      AvoirRemb.create!(
        commande: commande,
        type_avoir_remb: "remboursement",
        montant: 20,
        nature: EshopCommandeRemboursementService::NATURE_REMBOURSEMENT,
        custom_date: Date.current
      )

      get :index

      expect(response).to have_http_status(:ok)
      expect(assigns(:total_stripe_eur)).to eq(45.to_d)
      expect(assigns(:totalPrixCaStripe)).to eq(45.to_d)
    end
  end
end
