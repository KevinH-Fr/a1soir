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
    it "redirects back with destroy_blocked when legacy paiements exist" do
      skip "pas de table paiements" unless Commande.connection.data_source_exists?("paiements")

      Commande.connection.execute(
        Commande.sanitize_sql_array([
          "INSERT INTO paiements (typepaiement, montant, commande_id, moyen, commentaires, created_at, updated_at) " \
          "VALUES (?, ?, ?, ?, ?, datetime('now'), datetime('now'))",
          "prix",
          10,
          commande.id,
          "cb",
          nil
        ])
      )

      referer = "http://admin.lvh.me/previous"
      request.env["HTTP_REFERER"] = referer

      expect { delete :destroy, params: { id: commande.id } }.not_to change(Commande, :count)

      expect(response).to redirect_to(referer)
      expect(flash[:admin_toasts]).to include(
        a_hash_including(
          "variant" => "warning",
          "message" => I18n.t("admin.toasts.commande.destroy_blocked")
        )
      )
    end

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
