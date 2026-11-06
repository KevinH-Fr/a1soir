# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ProduitsController, type: :controller do
  let!(:produit_base) do
    Produit.create!(nom: "Robe dupliquer spec", reffrs: "DUP-#{SecureRandom.hex(4)}")
  end

  before do
    @request.host = "admin.lvh.me"
    allow(controller).to receive(:authenticate_vendeur_or_admin!).and_return(true)
    allow(controller).to receive(:current_admin_user).and_return(
      instance_double(User, admin?: true, vendeur?: false)
    )
    allow(OnlineSales).to receive(:available?).and_return(false)
    allow(GenerateQr).to receive(:call)
  end

  def attach_sample_video(produit)
    produit.video1.attach(
      io: StringIO.new("fake-video"),
      filename: "sample.mp4",
      content_type: "video/mp4"
    )
  end

  describe "GET #index" do
    let!(:mariage) { Produit.create!(nom: "Robe mariage liste", prixvente: 10, quantite: 1) }
    let!(:costume) do
      Produit.create!(
        nom: "Habit epoque liste",
        prixvente: 10,
        quantite: 1,
        catalogue: Produit::CATALOGUE_COSTUME_EPOQUE_DEGUISEMENTS
      )
    end

    it "opens on the wedding catalogue" do
      get :index

      ids = assigns(:produits).map(&:id)
      expect(ids).to include(mariage.id)
      expect(ids).not_to include(costume.id)
    end

    it "lists both catalogues when filter_catalogue is tous" do
      get :index, params: { filter_catalogue: "tous" }

      ids = assigns(:produits).map(&:id)
      expect(ids).to include(mariage.id, costume.id)
    end

    it "filters the costume catalogue by rubrique" do
      rubrique = RubriqueCostume.create!(nom: "Carnaval spec", position: 1)
      costume.rubrique_costumes << rubrique
      Produit.create!(
        nom: "Autre costume liste",
        prixvente: 10,
        quantite: 1,
        catalogue: Produit::CATALOGUE_COSTUME_EPOQUE_DEGUISEMENTS
      )

      get :index, params: {
        filter_catalogue: Produit::CATALOGUE_COSTUME_EPOQUE_DEGUISEMENTS,
        filter_rubrique: rubrique.id
      }

      expect(assigns(:produits).map(&:id)).to contain_exactly(costume.id)
    end

    it "hides the analysis mode button and filters by statut" do
      archived = Produit.create!(nom: "Robe archivee liste", prixvente: 10, quantite: 0, actif: false, eshop: false)
      archived.update_column(:today_availability, false)
      mariage.update!(eshop: true, quantite: 1)

      get :index, params: { filter_statut: %w[actif eshop dispo] }

      expect(response.body).not_to include("filter_modeDropdown")
      expect(assigns(:produits).map(&:id)).to include(mariage.id)
      expect(assigns(:produits).map(&:id)).not_to include(archived.id, costume.id)
    end

    it "lists a product of both catalogues in each catalogue filter" do
      les_deux = Produit.create!(
        nom: "Robe des deux catalogues",
        prixvente: 10,
        quantite: 1,
        catalogue: Produit::CATALOGUE_LES_DEUX
      )

      get :index, params: {
        q: { nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont: "deux catalogues" }
      }

      expect(assigns(:produits).map(&:id)).to contain_exactly(les_deux.id)
      expect(assigns(:produits).map(&:catalogue_label)).to eq(["Les deux"])

      get :index, params: {
        filter_catalogue: Produit::CATALOGUE_COSTUME_EPOQUE_DEGUISEMENTS,
        q: { nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont: "deux catalogues" }
      }

      expect(assigns(:produits).map(&:id)).to contain_exactly(les_deux.id)
      expect(assigns(:produits).map(&:id)).not_to include(costume.id)
    end

    it "ignores a rubrique filter on the wedding catalogue" do
      rubrique = RubriqueCostume.create!(nom: "Carnaval ignore", position: 1)
      costume.rubrique_costumes << rubrique

      get :index, params: { filter_rubrique: rubrique.id }

      ids = assigns(:produits).map(&:id)
      expect(ids).to include(mariage.id)
      expect(ids).not_to include(costume.id)
    end
  end

  describe "GET #dupliquer" do
    it "copies video1 blob when source has a video" do
      attach_sample_video(produit_base)
      source_blob_id = produit_base.video1.blob.id

      get :dupliquer, params: { id: produit_base.id, produitbase: produit_base.id }

      copy = Produit.order(:id).last
      expect(copy).not_to eq(produit_base)
      expect(copy.video1).to be_attached
      expect(copy.video1.blob.id).to eq(source_blob_id)
      expect(response).to redirect_to(admin_produit_path(copy))
    end

    it "duplicates without error when source has no video" do
      expect(produit_base.video1).not_to be_attached

      get :dupliquer, params: { id: produit_base.id, produitbase: produit_base.id }

      copy = Produit.order(:id).last
      expect(copy.video1).not_to be_attached
      expect(response).to redirect_to(admin_produit_path(copy))
    end

    it "redirects with error when produitbase is missing" do
      get :dupliquer, params: { id: produit_base.id }

      expect(Produit.count).to eq(1)
      expect(response).to redirect_to(admin_produit_path(produit_base))
    end
  end
end
