# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public::Mensurations", type: :request do
  let!(:invitation) do
    MensurationInvitation.create!(
      email: "cliente@example.com", template: "femme", locale: "fr",
      prenom: "Anna", nom: "Durand"
    )
  end

  # JPEG 1×1 : si l'analyse des dimensions échoue, la validation serveur accepte le fichier.
  def mensuration_jpeg_path
    path = Rails.root.join("tmp/pied.jpg")
    FileUtils.mkdir_p(path.dirname)
    File.binwrite(path, Base64.decode64(
      "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB" \
      "AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEB" \
      "AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAAR" \
      "CAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAn/xAAUEAEAAAAAAAAAAAAA" \
      "AAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oA" \
      "DAMBAAIQAxAAAAGf/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA="
    ))
    path
  end

  # La session OTP est ouverte via le flux réel (verify) pour rester au niveau requête.
  def open_otp_session(inv = invitation)
    code = inv.generate_otp!
    post "/#{inv.locale.presence || "fr"}/m/#{inv.token}/verify", params: { code: code }
  end

  describe "GET /mensurations" do
    it "affiche la landing captcha, sans être avalée par le catch-all SEO" do
      get "/mensurations"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("mensurations.share.welcome", locale: :fr))
      expect(response.body).to include("mensuration-card-header")
      expect(response.body).to include('data-controller="share-gate"')
      expect(response.body).to include('data-share-gate-target="captcha"')
      expect(response.body).to include("mensuration-gate__captcha is-locked")
      expect(response.body).not_to include("d-none mensuration-gate__captcha")
      expect(response.body).to include('name="email"')
      expect(response.body).to include('name="form_locale"')
      expect(response.body).to include(I18n.t("mensurations.share.locale_fr", locale: :fr))
      expect(response.body).to include(I18n.t("mensurations.share.locale_en", locale: :en))
      expect(response.body).to include(I18n.t("mensurations.share.intro", locale: :fr))
      expect(response.body).to include(I18n.t("mensurations.share.intro_email", locale: :fr))
      expect(response.body).to include(ERB::Util.html_escape(I18n.t("mensurations.share.hint_email", locale: :fr)))
      expect(response.body).to include(I18n.t("mensurations.share.email_placeholder", locale: :fr))
      expect(response.body).not_to include(I18n.t("mensurations.share.template_femme", locale: :fr))
      expect(response.body).not_to include(I18n.t("mensurations.share.template_homme", locale: :fr))
      expect(response.body).to include("noindex, nofollow, noarchive")
      expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow, noarchive")
    end

    it "passe en anglais via le sélecteur de la navbar" do
      get "/mensurations", params: { locale: "en" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("mensurations.share.welcome", locale: :en))
      expect(response.body).to include(I18n.t("mensurations.share.intro", locale: :en))
      expect(response.body).to include(I18n.t("mensurations.share.intro_email", locale: :en))
      expect(response.body).to include(I18n.t("mensurations.share.hint_email", locale: :en))
      expect(response.body).not_to include(I18n.t("mensurations.share.template_femme", locale: :en))
    end

    it "redirige les anciens chemins /fr/m et /en/m" do
      get "/fr/m"
      expect(response).to redirect_to("/mensurations")

      get "/en/m"
      expect(response).to redirect_to("/mensurations")
    end

    it "est listée en Disallow dans robots.txt" do
      get "/robots.txt"

      expect(response.body).to include("Disallow: /mensurations")
      expect(response.body).to include("Disallow: /fr/m/")
      expect(response.body).to include("Disallow: /en/m/")
    end
  end

  describe "POST /mensurations (lien partagé)" do
    def post_share(email:, form_locale: "fr", recaptcha: true)
      allow(RecaptchaVerifier).to receive(:verify).and_return(recaptcha)
      post "/mensurations", params: {
        email: email, form_locale: form_locale,
        "g-recaptcha-response" => (recaptcha ? "ok" : "")
      }
    end

    it "refuse sans captcha et n'envoie pas d'OTP" do
      expect {
        post_share(email: "a@example.com", recaptcha: false)
      }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)

      expect(response).to have_http_status(422)
      expect(MensurationInvitation.where(email: "a@example.com")).to be_empty
      expect(response.body).to include('data-share-gate-target="captcha"')
      expect(response.body).to include("mensuration-flash--alert")
    end

    it "crée une invitation, envoie l'OTP et redirige vers le token interne" do
      expect {
        post_share(email: "salarie@example.com")
      }.to change(MensurationInvitation, :count).by(1)
        .and have_enqueued_job(ActionMailer::MailDeliveryJob)

      invitation = MensurationInvitation.find_by!(email: "salarie@example.com")
      expect(response).to redirect_to("/fr/m/#{invitation.token}")
      expect(invitation.otp_digest).to be_present
      expect(invitation.template).to be_nil
      expect(invitation.locale).to eq("fr")
    end

    it "applique la langue choisie sur le lien unique" do
      post_share(email: "english@example.com", form_locale: "en")

      invitation = MensurationInvitation.find_by!(email: "english@example.com")
      expect(invitation.locale).to eq("en")
      expect(invitation.template).to be_nil
      expect(response).to redirect_to("/en/m/#{invitation.token}")
    end

    it "crée deux invitations pour deux e-mails" do
      expect {
        post_share(email: "un@example.com")
        post_share(email: "deux@example.com")
      }.to change(MensurationInvitation, :count).by(2)
    end

    it "reprend la même invitation pour le même e-mail" do
      post_share(email: "meme@example.com")
      first = MensurationInvitation.find_by!(email: "meme@example.com")

      expect {
        post_share(email: "meme@example.com")
      }.not_to change(MensurationInvitation, :count)

      expect(first.reload.token).to eq(first.token)
      expect(response).to redirect_to("/fr/m/#{first.token}")
    end

    it "n'ouvre pas le formulaire sans OTP, même si l'e-mail existe déjà" do
      post_share(email: "deja@example.com")
      invitation = MensurationInvitation.find_by!(email: "deja@example.com")

      get "/fr/m/#{invitation.token}"
      expect(response.body).to include(I18n.t("mensurations.share.welcome", locale: :fr))
      expect(response.body).to include(I18n.t("mensurations.otp.code_label", locale: :fr))
      expect(response.body).not_to include(I18n.t("mensurations.form.title_femme", locale: :fr))
      expect(response.body).not_to include('name="photo_pied"')
    end
  end

  describe "GET /fr/m/:token" do
    it "n'est pas avalée par le catch-all des pages SEO" do
      get "/fr/m/#{invitation.token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("mensurations.share.welcome", locale: :fr))
      expect(response.body).to include(I18n.t("mensurations.otp.send_code", locale: :fr))
    end

    it "est interdite d'indexation" do
      get "/fr/m/#{invitation.token}"

      expect(response.body).to include("noindex, nofollow, noarchive")
      expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow, noarchive")
    end

    it "retourne un 404 générique pour un token inconnu" do
      get "/fr/m/inconnu123"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Page introuvable")
    end

    it "retourne un 404 générique pour un lien expiré" do
      invitation.update!(expires_at: 1.hour.ago)

      get "/fr/m/#{invitation.token}"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Page introuvable")
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
      expect(response.body).to include('name="photo_pied"')
      expect(response.body).to include("photo-preview")
      expect(response.body).to include(I18n.t("mensurations.share.welcome", locale: :fr))
      expect(response.body).to include("mensuration-card-header")
      expect(response.body).to include(I18n.t("mensurations.share.template_femme", locale: :fr))
      expect(response.body).to include(I18n.t("mensurations.share.template_homme", locale: :fr))
      expect(response.body).to include('data-form-wizard-index-value="0"')
      expect(response.body).to include(I18n.t("mensurations.share.template_step", locale: :fr))
      expect(response.body).to include("measure-guide")
      expect(response.body).to include("/images/human_body.svg")
      expect(response.body).to include('data-clip="full"')
      expect(response.body).not_to include('data-clip="chest"')
    end

    it "refuse un mauvais code" do
      invitation.generate_otp!
      post "/fr/m/#{invitation.token}/verify", params: { code: "000000" }

      follow_redirect!
      expect(response.body).to include(I18n.t("mensurations.otp.invalid_code", locale: :fr))
      expect(response.body).to include(I18n.t("mensurations.otp.code_label", locale: :fr))
    end

    it "bloque la sauvegarde sans session vérifiée" do
      post "/fr/m/#{invitation.token}", params: { mensuration: { prenom: "Anna", nom: "Durand" } }

      expect(response).to redirect_to("/fr/m/#{invitation.token}")
      expect(Mensuration.count).to eq(0)
    end
  end

  describe "choix langue et formulaire après OTP" do
    before { open_otp_session }

    it "change la langue via le sélecteur de navbar" do
      get "/en/m/#{invitation.token}"

      expect(invitation.reload.locale).to eq("en")
      expect(response.body).to include(I18n.t("mensurations.share.welcome", locale: :en))
      expect(response.body).to include(I18n.t("mensurations.share.template_femme", locale: :en))
    end

    it "enregistre le formulaire et reprend aux coordonnées" do
      post "/fr/m/#{invitation.token}/template", params: { template: "homme" }

      expect(invitation.reload.template).to eq("homme")
      expect(response).to redirect_to("/fr/m/#{invitation.token}?resume=identity")
    end

    it "permet de changer le formulaire une fois la fiche enregistrée" do
      post "/fr/m/#{invitation.token}", params: {
        mensuration: { prenom: "Anna", nom: "Durand" },
        measurements: { hauteur: "168", taille_soutien_gorge: "90D" }
      }

      post "/fr/m/#{invitation.token}/template", params: { template: "homme" }

      expect(invitation.reload.template).to eq("homme")
      expect(invitation.mensuration.reload.template).to eq("homme")
      expect(invitation.mensuration.value_for("taille_soutien_gorge")).to be_nil
      expect(invitation.mensuration.value_for("hauteur")).to eq("168")
      expect(response).to redirect_to("/fr/m/#{invitation.token}?resume=identity")
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

      follow_redirect!
      expect(response.body).to include("mensuration-flash--saved")
      expect(response.body).to include(I18n.t("mensurations.form.thanks_title", locale: :fr))
      expect(response.body).to include(I18n.t("mensurations.form.show_answers", locale: :fr))
      expect(response.body).to include("d-none")
      expect(response.body).to include("mensuration-delete-link")
      expect(response.body).not_to include("btn-outline-danger")
      expect(response.body).to include("measure-guide")
    end

    it "rattache au client existant si l'e-mail correspond" do
      existing = Client.create!(nom: "Martin", mail: "cliente@example.com", tel: "0400000000")

      post "/fr/m/#{invitation.token}", params: {
        mensuration: { prenom: "Anna", nom: "Durand" },
        measurements: { hauteur: "168" }
      }

      expect(Mensuration.last.client).to eq(existing)
      expect(existing.reload.tel).to eq("0400000000")
      expect(existing.nom).to eq("Martin")
    end

    it "n'accepte pas un nom déjà connu ni un e-mail envoyés dans le POST" do
      post "/fr/m/#{invitation.token}", params: {
        mensuration: { prenom: "Anna", nom: "Martin", email: "autre@example.com" },
        measurements: { hauteur: "168" }
      }

      mensuration = Mensuration.last
      expect(mensuration.nom).to eq("Durand")
      expect(mensuration.client.mail).to eq("cliente@example.com")
    end

    it "accepte le nom s'il n'était pas encore renseigné, puis le verrouille" do
      invitation.update!(nom: nil)

      post "/fr/m/#{invitation.token}", params: {
        mensuration: { prenom: "Anna", nom: "Durand" },
        measurements: { hauteur: "168" }
      }
      expect(Mensuration.last.nom).to eq("Durand")

      post "/fr/m/#{invitation.token}", params: {
        mensuration: { prenom: "Anna", nom: "Martin" },
        measurements: { hauteur: "168" }
      }
      expect(Mensuration.last.reload.nom).to eq("Durand")
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

    it "attache une photo en pied JPEG" do
      photo = Rack::Test::UploadedFile.new(mensuration_jpeg_path, "image/jpeg", true)

      post "/fr/m/#{invitation.token}", params: {
        mensuration: { prenom: "Anna", nom: "Durand" },
        measurements: { hauteur: "168" },
        photo_pied: photo
      }

      mensuration = Mensuration.last
      expect(mensuration.photo_pied).to be_attached
      expect(mensuration.photo_pied.filename.to_s).to eq("pied.jpg")
      expect(mensuration.photo_pied.content_type).to eq("image/jpeg")
    end

    it "refuse une photo qui n'est pas une image" do
      file = Tempfile.new(["notes", ".txt"])
      file.write("pas une image")
      file.rewind

      post "/fr/m/#{invitation.token}", params: {
        mensuration: { prenom: "Anna", nom: "Durand" },
        measurements: { hauteur: "168" },
        photo_pied: Rack::Test::UploadedFile.new(file.path, "text/plain")
      }

      expect(Mensuration.count).to eq(0)
      expect(response).to have_http_status(422)
      expect(response.body).to include(I18n.t("mensurations.photo.invalid_format", locale: :fr))
    ensure
      file.close!
    end
  end

  describe "locale anglaise" do
    let!(:invitation_en) do
      MensurationInvitation.create!(email: "client@example.com", nom: "Test", template: "homme", locale: "en")
    end

    it "sert le formulaire homme en anglais" do
      code = invitation_en.generate_otp!
      post "/en/m/#{invitation_en.token}/verify", params: { code: code }

      get "/en/m/#{invitation_en.token}"
      expect(response.body).to include(I18n.t("mensurations.share.welcome", locale: :en))
      expect(response.body).to include(I18n.t("mensurations.fields.tour_cou.label", locale: :en))
      expect(response.body).to include("/images/human_body.svg")
      expect(response.body).to include('data-clip="neck"')
    end
  end
end
