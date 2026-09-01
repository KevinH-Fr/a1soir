# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public::Mensurations", type: :request do
  let!(:invitation) do
    MensurationInvitation.create!(
      email: "cliente@example.com", template: "femme", locale: "fr",
      prenom: "Anna", nom: "Durand"
    )
  end

  # La session OTP est ouverte via le flux réel (verify) pour rester au niveau requête.
  def open_otp_session(inv = invitation)
    code = inv.generate_otp!
    post "/#{inv.locale}/m/#{inv.token}/verify", params: { code: code }
  end

  describe "GET /fr/m/:token" do
    it "n'est pas avalée par le catch-all des pages SEO" do
      get "/fr/m/#{invitation.token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("mensurations.otp.request_title", locale: :fr))
    end

    it "est interdite d'indexation" do
      get "/fr/m/#{invitation.token}"

      expect(response.body).to include("noindex, nofollow, noarchive")
    end

    it "retourne un 404 générique pour un token inconnu" do
      get "/fr/m/inconnu123"

      expect(response).to have_http_status(:not_found)
    end

    it "retourne un 404 générique pour un lien expiré" do
      invitation.update!(expires_at: 1.hour.ago)

      get "/fr/m/#{invitation.token}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "flux OTP" do
    it "envoie un code par mail sur l'adresse de l'invitation" do
      expect {
        post "/fr/m/#{invitation.token}/otp"
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob)

      expect(invitation.reload.otp_digest).to be_present
    end

    it "ouvre la session et affiche le formulaire après un code valide" do
      open_otp_session
      expect(response).to redirect_to("/fr/m/#{invitation.token}")

      get "/fr/m/#{invitation.token}"
      expect(response.body).to include(I18n.t("mensurations.form.title_femme", locale: :fr))
    end

    it "refuse un mauvais code" do
      invitation.generate_otp!
      post "/fr/m/#{invitation.token}/verify", params: { code: "000000" }

      follow_redirect!
      expect(response.body).to include(I18n.t("mensurations.otp.request_title", locale: :fr))
    end

    it "bloque la sauvegarde sans session vérifiée" do
      post "/fr/m/#{invitation.token}", params: { mensuration: { prenom: "Anna", nom: "Durand" } }

      expect(response).to redirect_to("/fr/m/#{invitation.token}")
      expect(Mensuration.count).to eq(0)
    end
  end

  describe "sauvegarde" do
    before { open_otp_session }

    it "enregistre la fiche, ne garde que les champs du template et crée le client" do
      expect {
        post "/fr/m/#{invitation.token}", params: {
          mensuration: { prenom: "Anna", nom: "Durand", telephone: "0611111111", ville: "Cannes" },
          measurements: { hauteur: "168", taille_soutien_gorge: "90D", tour_cou: "40" }
        }
      }.to change(Mensuration, :count).by(1).and change(Client, :count).by(1)

      mensuration = Mensuration.last
      expect(mensuration.measurements).to eq("hauteur" => "168", "taille_soutien_gorge" => "90D")
      # tour_cou est un champ homme : ignoré sur une invitation femme.
      expect(mensuration.value_for("tour_cou")).to be_nil
      expect(mensuration.client.mail).to eq("cliente@example.com")
      expect(invitation.reload.status).to eq("completed")
    end

    it "rattache au client existant si mail + nom correspondent" do
      existing = Client.create!(nom: "Durand", mail: "cliente@example.com", tel: "0400000000")

      post "/fr/m/#{invitation.token}", params: {
        mensuration: { prenom: "Anna", nom: "Durand" },
        measurements: { hauteur: "168" }
      }

      expect(Mensuration.last.client).to eq(existing)
      expect(existing.reload.tel).to eq("0400000000")
    end

    it "supprime la fiche à la demande du client" do
      post "/fr/m/#{invitation.token}", params: {
        mensuration: { prenom: "Anna", nom: "Durand" },
        measurements: { hauteur: "168" }
      }

      expect {
        delete "/fr/m/#{invitation.token}"
      }.to change(Mensuration, :count).by(-1)

      expect(invitation.reload.status).to eq("verified")
    end
  end

  describe "locale anglaise" do
    let!(:invitation_en) do
      MensurationInvitation.create!(email: "client@example.com", template: "homme", locale: "en")
    end

    it "sert le formulaire homme en anglais" do
      code = invitation_en.generate_otp!
      post "/en/m/#{invitation_en.token}/verify", params: { code: code }

      get "/en/m/#{invitation_en.token}"
      expect(response.body).to include(I18n.t("mensurations.form.title_homme", locale: :en))
      expect(response.body).to include(I18n.t("mensurations.fields.tour_cou.label", locale: :en))
    end
  end
end
