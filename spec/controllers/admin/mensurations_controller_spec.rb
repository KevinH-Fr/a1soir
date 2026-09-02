# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::MensurationsController, type: :controller do
  let!(:invitation) do
    MensurationInvitation.create!(email: "cliente@example.com", nom: "Durand", template: "femme", locale: "fr")
  end

  def stub_staff_session
    allow(controller).to receive(:authenticate_vendeur_or_admin!).and_return(true)
    allow(controller).to receive(:current_admin_user).and_return(
      instance_double(User, admin?: true, vendeur?: false)
    )
  end

  before { @request.host = "admin.lvh.me" }

  describe "POST #create" do
    before { stub_staff_session }

    it "crée l'invitation et envoie le mail" do
      mail = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
      expect(MensurationMailer).to receive(:invitation).and_return(mail)

      expect {
        post :create, params: { mensuration_invitation: { email: "new@example.com", template: "homme", locale: "en" } }
      }.to change(MensurationInvitation, :count).by(1)

      expect(MensurationInvitation.last.token).to be_present
    end
  end

  describe "DELETE #destroy" do
    before { stub_staff_session }

    it "supprime invitation, fiche et photo (purge), pas le client" do
      client = Client.create!(nom: "Durand", mail: "cliente@example.com")
      mensuration = Mensuration.create!(
        mensuration_invitation: invitation, client: client,
        template: "femme", locale: "fr", prenom: "Anna", nom: "Durand",
        measurements: { "hauteur" => "168" }
      )
      mensuration.photo_pied.attach(io: StringIO.new("fake-image"), filename: "pied.jpg", content_type: "image/jpeg")

      expect {
        delete :destroy, params: { id: invitation.id }
      }.to change(Mensuration, :count).by(-1)
        .and change(MensurationInvitation, :count).by(-1)
        # La purge du blob part en job (purge_later) : on vérifie l'enqueue, pas l'exécution.
        .and have_enqueued_job(ActiveStorage::PurgeJob)

      expect(Client.exists?(client.id)).to be(true)
    end
  end

  describe "GET #photo" do
    let!(:mensuration) do
      Mensuration.create!(
        mensuration_invitation: invitation,
        template: "femme", locale: "fr", prenom: "Anna", nom: "Durand"
      ).tap do |m|
        m.photo_pied.attach(io: StringIO.new("fake-image"), filename: "pied.jpg", content_type: "image/jpeg")
      end
    end

    context "sans session staff" do
      it "ne sert pas la photo" do
        get :photo, params: { id: invitation.id }

        expect(response).not_to be_redirect
        expect(response.body).not_to include("cloudinary")
      end
    end

    context "avec session staff" do
      before do
        stub_staff_session
        ActiveStorage::Current.url_options = { host: "http://admin.lvh.me" }
      end

      it "sert la photo en inline, sans URL de téléchargement Cloudinary" do
        get :photo, params: { id: invitation.id }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("image/jpeg")
        expect(response.body).not_to include("image/download")
      end

      it "retourne 404 si aucune photo" do
        mensuration.photo_pied.purge

        expect {
          get :photo, params: { id: invitation.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
