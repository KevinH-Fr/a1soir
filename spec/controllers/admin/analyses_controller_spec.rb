# frozen_string_literal: true

# Specs du dashboard Analyses : période par défaut, CA Stripe net, métriques du dataset fixe.
require "rails_helper"

RSpec.describe Admin::AnalysesController, type: :controller do
  render_views

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
    AdminParameter.create!(tx_tva: 20) if AdminParameter.none?
    allow(controller).to receive(:authenticate_vendeur_or_admin!).and_return(true)
    allow(controller).to receive(:current_admin_user).and_return(
      instance_double(User, admin?: true, vendeur?: false, role: "admin")
    )
  end

  describe "GET #index" do
    it "redirects to default 30-day period when dates are missing" do
      travel_to Time.zone.local(2026, 3, 15, 12, 0, 0) do
        debut, fin = Date.current - 29, Date.current

        get :index

        expect(response).to redirect_to(admin_analyses_index_path(debut: debut, fin: fin))
      end
    end

    it "nets Stripe CA by eshop remboursements" do
      allow(GenerateQr).to receive(:call)

      commande = Commande.create!(
        client: client,
        profile: profile,
        nom: "E-shop CA",
        montant: 65,
        devis: false,
        type_locvente: "vente",
        typeevent: Commande::EVENEMENTS_OPTIONS.first,
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

      get :index, params: { debut: Date.current.to_s, fin: Date.current.to_s, vue: "synthese" }

      expect(response).to have_http_status(:ok)
      expect(assigns(:total_stripe_eur)).to eq(45.to_d)
      expect(assigns(:totalPrixCaStripe)).to eq(45.to_d)
      expect(assigns(:timeline_grain)).to eq(:hour)
      expect(response.body).to include("analyses-chart-synthese-mixed")
      expect(response.body).to match(/_grain(?:\\u0022|&quot;|")\s*:\s*(?:\\u0022|&quot;|")hour/)
    end

    context "with analyses dashboard dataset" do
      before { AnalysesDashboardDataset.seed! }

      let(:period) { AnalysesDashboardDataset.period_params }

      it "counts a paiement by custom_date even if the commande is outside the period" do
        data = AnalysesDashboardDataset.data
        old_commande = Commande.create!(
          client: Client.create!(
            nom: "Ancienne",
            prenom: "Cmd",
            propart: "particulier",
            intitule: Client::INTITULE_OPTIONS.first,
            mail: "ancienne-#{SecureRandom.hex(4)}@test.com"
          ),
          profile: data[:profile_a],
          nom: "Commande 2025 payée en mars",
          montant: 50,
          devis: false,
          type_locvente: "vente",
          created_at: Time.zone.local(2025, 6, 1, 10, 0, 0)
        )
        PaiementRecu.create!(
          commande: old_commande,
          typepaiement: "prix",
          montant: 50,
          moyen: "espèces",
          custom_date: Date.new(2026, 3, 5),
          created_at: Time.zone.local(2025, 6, 2, 11, 0, 0)
        )

        get :index, params: period.merge(vue: "ca")

        expected = AnalysesDashboardDataset.expected_baseline
        expect(assigns(:totalPrixCaEspeces)).to eq(50.to_d)
        expect(assigns(:totalPrixCa)).to eq(expected[:total_prix_ca] + 50)
        expect(assigns(:nbTotal)).to eq(expected[:nb_total_commandes])
      end

      it "returns baseline metrics for the fixed period on synthese vue" do
        expected = AnalysesDashboardDataset.expected_baseline

        get :index, params: period.merge(vue: "synthese")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("analyses-chart-synthese-mixed")
        expect(response.body).to include("analyses-chart-synthese-catalog-categories")
        expect(response.body).to include("analyses-chart-synthese-profiles-bars")
        expect(assigns(:catalog_by_categorie)).to be_present
        expect(assigns(:stats_par_profile)).to be_present
        expect(response.body).to include('id="analysesFiltersOffcanvas"')
        expect(response.body).to include('data-bs-target="#analysesFiltersOffcanvas"')
        expect(response.body).not_to include("bi-filter-circle")
        expect(assigns(:nbTotal)).to eq(expected[:nb_total_commandes])
        expect(assigns(:nbTotalArticles)).to eq(expected[:nb_total_articles])
        expect(assigns(:total_stripe_eur)).to eq(expected[:total_stripe_eur])
        expect(assigns(:totalPrixCa)).to eq(expected[:total_prix_ca])
        expect(assigns(:totalPrixCaCb)).to eq(expected[:total_prix_ca_cb])
        expect(assigns(:totalPrixCaEspeces)).to eq(expected[:total_prix_ca_especes])
        expect(assigns(:analyses_ca_mode)).to eq(:paiements)
      end

      it "renders catalogue vue with toggleable locvente doughnut and ranking charts" do
        get :index, params: period.merge(vue: "catalogue")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("analyses-chart-locvente-catalogue")
        expect(response.body).to include("analyses-chart-catalog-categories")
        expect(response.body).to include("analyses-chart-catalog-types")
        expect(response.body).to include('data-controller="analyses-segment-toggle"')
        expect(response.body).not_to include("analyses-locvente-twins")
        expect(assigns(:catalog_top_products_by_qty)).to be_present
        expect(assigns(:catalog_top_products_by_ca)).to be_present
        expect(assigns(:catalog_by_type_by_ca)).to be_present
        expect(assigns(:catalog_by_categorie_by_ca)).to be_present
      end

      it "returns transaction metrics on ca vue" do
        expected = AnalysesDashboardDataset.expected_baseline

        get :index, params: period.merge(vue: "ca")

        expect(response).to have_http_status(:ok)
        expect(assigns(:totalTransactionsLoc)).to eq(expected[:total_transactions_loc])
        expect(assigns(:totalTransactions)).to eq(expected[:total_transactions])
        expect(assigns(:totalPrixCa)).to be < assigns(:totalTransactions)
        expect(response.body).to include("analyses-chart-ca-transactions")
        expect(response.body).to include("analyses-chart-ca_payment_modes_doughnut")
      end

      it "filters by profile on synthese vue" do
        data = AnalysesDashboardDataset.data

        get :index, params: period.merge(filter_profile: data[:profile_a].id)

        expect(assigns(:nbTotal)).to eq(2)
      end

      it "accepts several profiles at once" do
        data = AnalysesDashboardDataset.data

        get :index, params: period.merge(filter_profile: [data[:profile_a].id, data[:profile_b].id])

        expect(assigns(:nbTotal)).to eq(4)
      end

      it "accepts several product types at once" do
        data = AnalysesDashboardDataset.data

        get :index, params: period.merge(
          filter_type_produit: [data[:type_robe].id, data[:type_costume].id],
          vue: "catalogue"
        )

        expect(assigns(:analyses_ca_mode)).to eq(:lignes)
        expect(assigns(:line_metrics).produits_count).to eq(2)
      end

      it "switches to line-based CA when filtering by product type" do
        data = AnalysesDashboardDataset.data

        get :index, params: period.merge(filter_type_produit: data[:type_robe].id, vue: "synthese")

        expect(assigns(:analyses_ca_mode)).to eq(:lignes)
        expect(assigns(:totalPrixCaCb)).to eq(0.to_d)
        # Boutique robes (100 + 40) + Stripe robe (60) − remboursement e-shop (20) = 180
        expect(assigns(:totalPrixCa)).to eq(180.to_d)
        expect(assigns(:totalPrixCaStripe)).to eq(40.to_d)
      end

      it "accepts several categories at once" do
        data = AnalysesDashboardDataset.data
        cat_a = CategorieProduit.create!(nom: "soirée dataset #{SecureRandom.hex(2)}")
        cat_b = CategorieProduit.create!(nom: "mariage dataset #{SecureRandom.hex(2)}")
        data[:produit_robe].categorie_produits << cat_a
        data[:produit_costume].categorie_produits << cat_b

        get :index, params: period.merge(filter_categorie: [cat_a.id, cat_b.id], vue: "catalogue")

        expect(assigns(:analyses_ca_mode)).to eq(:lignes)
        expect(assigns(:line_metrics).produits_count).to eq(2)

        get :index, params: period.merge(filter_categorie: cat_a.id, vue: "synthese")

        expect(assigns(:line_metrics).produits_count).to eq(1)
        expect(assigns(:totalPrixCa)).to eq(180.to_d)
      end

      it "filters by fournisseur like other product dimensions" do
        data = AnalysesDashboardDataset.data

        get :index, params: period.merge(filter_fournisseur: data[:fournisseur].id, vue: "synthese")

        expect(assigns(:analyses_ca_mode)).to eq(:lignes)
        expect(response.body).to include("Fournisseur")
        # Même périmètre que le filtre type robe (produit_robe uniquement).
        expect(assigns(:totalPrixCa)).to eq(180.to_d)
      end

      it "filters by client type particulier / professionnel" do
        get :index, params: period.merge(filter_propart: "particulier", vue: "synthese")
        expect(assigns(:nbTotal)).to eq(AnalysesDashboardDataset.expected_baseline[:nb_total_commandes])

        get :index, params: period.merge(filter_propart: "professionnel", vue: "synthese")
        expect(assigns(:nbTotal)).to eq(0)
        expect(response.body).to include("Type de client")
      end

      it "counts e-shop Stripe lines as vente articles" do
        get :index, params: period.merge(filter_eshop: "true", vue: "synthese")

        expect(assigns(:nbTotalArticles)).to eq(2)
        expect(assigns(:nbVente)).to eq(2)
        expect(assigns(:nbLoc)).to eq(0)
        expect(assigns(:totalPrixCaStripe)).to eq(80.to_d)
      end

      it "excludes e-shop Stripe lines when filtering location" do
        get :index, params: period.merge(filter_locvente: "location", vue: "synthese")

        expect(assigns(:nbVente)).to eq(0)
        expect(assigns(:nbLoc)).to eq(3)
        expect(assigns(:nbTotalArticles)).to eq(3)
        expect(assigns(:total_stripe_eur)).to eq(0.to_d)
      end

      it "filters location articles only" do
        get :index, params: period.merge(filter_locvente: "location", vue: "ca")

        expect(assigns(:analyses_ca_mode)).to eq(:lignes)
        expect(assigns(:totalTransactionsLoc)).to eq(140.to_d)
        expect(assigns(:totalTransactionsVente)).to eq(0.to_d)
      end

      it "filters by profile on equipe vue" do
        data = AnalysesDashboardDataset.data

        get :index, params: period.merge(vue: "equipe", filter_profile: data[:profile_a].id)

        expect(assigns(:stats_par_profile).size).to eq(1)
      end
    end
  end
end
