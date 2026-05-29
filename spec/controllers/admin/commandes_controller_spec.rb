# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CommandesController, type: :controller do
  let(:client) do
    Client.create!(
      nom: "Dupont",
      prenom: "Jean",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "admin-destroy-#{SecureRandom.hex(4)}@test.com"
    )
  end

  let(:profile) { Profile.create!(prenom: "Vendeur", nom: "Test") }

  let!(:commande) do
    Commande.create!(
      client: client,
      profile: profile,
      nom: "Commande destroy spec",
      montant: 100,
      devis: false,
      type_locvente: "vente",
      typeevent: Commande::EVENEMENTS_OPTIONS.first
    )
  end

  before do
    @request.host = "admin.lvh.me"
    allow(controller).to receive(:authenticate_vendeur_or_admin!).and_return(true)
    allow(controller).to receive(:current_admin_user).and_return(
      instance_double(User, admin?: true, vendeur?: false)
    )
  end

  describe "POST #rembourser_eshop" do
    let!(:eshop_commande) do
      Commande.create!(
        client: client,
        profile: profile,
        nom: "E-shop remb ctrl",
        montant: 50,
        devis: false,
        type_locvente: "vente",
        eshop: true
      )
    end

    before do
      StripePayment.create!(
        commande: eshop_commande,
        stripe_payment_id: "pi_ctrl_#{SecureRandom.hex(6)}",
        amount: 5000,
        currency: "eur",
        status: "paid"
      )
    end

    it "marks commande as remboursee and redirects" do
      post :rembourser_eshop, params: { id: eshop_commande.id }

      expect(response).to redirect_to(admin_commande_url(eshop_commande, host: "admin.lvh.me"))
      expect(eshop_commande.reload.remboursee_eshop?).to be(true)
      expect(flash[:admin_toasts]).to include(
        a_hash_including("message" => I18n.t("admin.toasts.commande.remboursee_ok"))
      )
    end
  end

  describe "DELETE #destroy" do
    it "destroys the commande and sets destroyed toast when allowed" do
      expect { delete :destroy, params: { id: commande.id } }.to change(Commande, :count).by(-1)

      expect(response).to redirect_to(admin_root_url(host: "admin.lvh.me"))
      expect(flash[:admin_toasts]).to include(
        a_hash_including(
          "variant" => "danger",
          "message" => I18n.t("admin.toasts.commande.destroyed")
        )
      )
    end
  end
end
