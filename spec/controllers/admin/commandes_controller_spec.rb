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
