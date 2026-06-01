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
