# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ArticlesController, type: :controller do
  let(:client) do
    Client.create!(
      nom: "Dupont",
      prenom: "Jean",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "articles-#{SecureRandom.hex(4)}@test.com"
    )
  end

  let(:profile) { Profile.create!(prenom: "Vendeur", nom: "Test") }

  let!(:produit) { Produit.create!(nom: "Article produit", prixvente: 40, quantite: 3) }

  before do
    @request.host = "admin.lvh.me"
    allow(controller).to receive(:authenticate_vendeur_or_admin!).and_return(true)
    allow(controller).to receive(:current_admin_user).and_return(
      instance_double(User, admin?: true, vendeur?: false)
    )
  end

  describe "DELETE #destroy" do
    context "boutique commande" do
      let!(:commande) do
        Commande.create!(
          client: client,
          profile: profile,
          nom: "Boutique",
          montant: 40,
          devis: false,
          type_locvente: "vente",
          typeevent: Commande::EVENEMENTS_OPTIONS.first
        )
      end

      let!(:article) do
        Article.create!(commande: commande, produit: produit, quantite: 1, prix: 40, total: 40, locvente: "vente")
      end

      it "destroys the article without creating an AvoirRemb" do
        expect {
          delete :destroy, params: { id: article.id }
        }.to change(Article, :count).by(-1)
          .and change(AvoirRemb, :count).by(0)

        expect(response).to redirect_to(admin_commande_url(commande, host: "admin.lvh.me"))
      end
    end

    context "paid eshop commande" do
      let!(:commande) do
        Commande.create!(
          client: client,
          profile: profile,
          nom: "E-shop",
          montant: 45,
          devis: false,
          type_locvente: "vente",
          eshop: true
        )
      end

      let!(:stripe_payment) do
        StripePayment.create!(
          commande: commande,
          stripe_payment_id: "pi_art_#{SecureRandom.hex(6)}",
          amount: 4500,
          currency: "eur",
          status: "paid"
        )
      end

      let!(:stripe_item) do
        StripePaymentItem.create!(
          stripe_payment: stripe_payment,
          produit: produit,
          quantity: 1,
          unit_amount: 4000
        )
      end

      let!(:article) do
        Article.create!(commande: commande, produit: produit, quantite: 1, prix: 40, total: 40, locvente: "vente")
      end

      it "refunds the line via the service" do
        delete :destroy, params: { id: article.id }

        expect(Article.exists?(article.id)).to be(false)
        expect(stripe_item.reload.refunded_at).to be_present
        expect(stripe_payment.reload.amount).to eq(4500)
        expect(commande.reload.devis?).to be(true)
        expect(commande.avoir_rembs.remb_only.sole.montant).to eq(45.0)
      end
    end
  end
end
