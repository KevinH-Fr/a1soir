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

  def identity_params
    { prenom: "Anna", nom: "Durand", telephone: "0611111111", ville: "Cannes" }
  end

  def patch_step(inv, params)
    patch "/#{inv.locale.presence || "fr"}/m/#{inv.token}/step",
          params: params,
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  def advance_through_femme_form(inv = invitation)
    patch_step(inv, { step: "identity", direction: "next", mensuration: identity_params })
    patch_step(inv, { step: "mesures.hauteur", direction: "next", measurements: { hauteur: "168" } })
    patch_step(inv, {
      step: "mesures.vetements", direction: "next",
      measurements: { taille_soutien_gorge: "90D", taille_veste_chemisier: "38" }
    })
  end

  def complete_femme_form(inv = invitation, **extra)
    advance_through_femme_form(inv)
    post "/fr/m/#{inv.token}/complete", params: extra
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
      expect(response).to redirect_to("/fr/m/#{invitation.token}?step=identity")
      follow_redirect!
      expect(response.body).to include('name="mensuration[prenom]"')
      expect(response.body).to include('id="mensuration_step"')
      expect(response.body).to include(I18n.t("mensurations.share.welcome", locale: :fr))
      expect(response.body).to include("mensuration-card-header")
      expect(response.body).to include('id="mensuration_step"')
      expect(response.body).to include(I18n.t("mensurations.form.identity_title", locale: :fr))
      expect(response.body).not_to include("measure-guide")
    end

    it "n'affiche aucun type de formulaire présélectionné sur une fiche vierge" do
      virgin = MensurationInvitation.create!(email: "vierge@example.com", locale: "fr")
      code = virgin.generate_otp!
      post "/fr/m/#{virgin.token}/verify", params: { code: code }

      get "/fr/m/#{virgin.token}"

      expect(virgin.reload.template).to be_nil
      expect(response.body).to include(I18n.t("mensurations.share.template_femme", locale: :fr))
      expect(response.body).to include(I18n.t("mensurations.share.template_homme", locale: :fr))
      expect(response.body).not_to include('id="mensuration_step"')
    end

    it "refuse un mauvais code" do
      invitation.generate_otp!
      post "/fr/m/#{invitation.token}/verify", params: { code: "000000" }

      follow_redirect!
      expect(response.body).to include(I18n.t("mensurations.otp.invalid_code", locale: :fr))
      expect(response.body).to include(I18n.t("mensurations.otp.code_label", locale: :fr))
    end

    it "bloque la finalisation sans session vérifiée" do
      post "/fr/m/#{invitation.token}/complete", params: { mensuration: { prenom: "Anna", nom: "Durand" } }

      expect(response).to redirect_to("/fr/m/#{invitation.token}")
      expect(Mensuration.count).to eq(0)
    end
  end

  describe "choix langue et formulaire après OTP" do
    before { open_otp_session }

    it "change la langue via le sélecteur de navbar" do
      get "/en/m/#{invitation.token}"

      expect(invitation.reload.locale).to eq("en")
      expect(response).to redirect_to("/en/m/#{invitation.token}?step=identity")
      follow_redirect!
      expect(response.body).to include(I18n.t("mensurations.share.welcome", locale: :en))
      expect(response.body).to include(I18n.t("mensurations.form.identity_title", locale: :en))
    end

    it "enregistre le formulaire et reprend aux coordonnées" do
      post "/fr/m/#{invitation.token}/template", params: { template: "homme" }

      expect(invitation.reload.template).to eq("homme")
      expect(response).to redirect_to("/fr/m/#{invitation.token}?step=identity")
    end

    it "permet de changer le formulaire une fois la fiche enregistrée" do
      complete_femme_form

      post "/fr/m/#{invitation.token}/template", params: { template: "homme" }

      expect(invitation.reload.template).to eq("homme")
      expect(invitation.mensuration.reload.template).to eq("homme")
      expect(invitation.mensuration.value_for("taille_soutien_gorge")).to be_nil
      expect(invitation.mensuration.value_for("hauteur")).to eq("168")
      expect(response).to redirect_to("/fr/m/#{invitation.token}?edit=1&step=identity")
    end
  end

  describe "navigation Merci / édition" do
    before { open_otp_session }

    def save_mensuration
      complete_femme_form
    end

    it "affiche la page Merci après enregistrement avec lien d'édition" do
      save_mensuration
      follow_redirect!

      expect(response.body).to include("mensuration-form__thanks")
      expect(response.body).to include(I18n.t("mensurations.form.thanks_title", locale: :fr))
      expect(response.body).to include("edit=1")
      expect(response.body).to include("step=identity")
      expect(response.body).to include("mensuration-delete-link")
      expect(response.body).not_to include("form-reveal")
      expect(response.body).not_to include(I18n.t("mensurations.form.hide_answers", locale: :fr))
      expect(response.body).not_to include("measure-guide")
    end

    it "ouvre le wizard en édition avec retour vers Merci" do
      save_mensuration

      get "/fr/m/#{invitation.token}", params: { edit: 1, step: "identity" }

      expect(response.body).to include('id="mensuration_step"')
      expect(response.body).to include(I18n.t("mensurations.form.identity_title", locale: :fr))
      expect(response.body).not_to include("mensuration-form__thanks")
    end

    it "met à jour la fiche déjà enregistrée sans recréer le client" do
      save_mensuration
      mensuration = invitation.reload.mensuration
      client = mensuration.client

      patch "/fr/m/#{invitation.token}/step", params: {
        step: "identity", direction: "next",
        mensuration: { prenom: "Anna", nom: "Durand", telephone: "0699999999" }
      }

      expect(response).to redirect_to("/fr/m/#{invitation.token}?step=mesures.hauteur")
      mensuration.reload
      expect(mensuration.telephone).to eq("0699999999")
      expect(mensuration.value_for("hauteur")).to eq("168")
      expect(mensuration.value_for("taille_soutien_gorge")).to eq("90D")
      expect(mensuration.client).to eq(client)
      expect(Client.count).to eq(1)
      expect(invitation.reload.status).to eq("completed")
    end

    it "redirige le changement de template vers l'édition si la fiche est enregistrée" do
      save_mensuration

      post "/fr/m/#{invitation.token}/template", params: { template: "homme" }

      expect(response).to redirect_to("/fr/m/#{invitation.token}?edit=1&step=identity")
    end

    it "redirige le changement de template vers les coordonnées au premier envoi" do
      post "/fr/m/#{invitation.token}/template", params: { template: "homme" }

      expect(response).to redirect_to("/fr/m/#{invitation.token}?step=identity")
    end

    it "revient au choix femme/homme depuis les coordonnées" do
      post "/fr/m/#{invitation.token}/template", params: { template: "homme" }
      get "/fr/m/#{invitation.token}", params: { step: "identity" }

      expect(response.body).to include(mensuration_template_reset_path(token: invitation.token, locale: "fr"))
      expect(response.body).to include('data-turbo-method="delete"')

      delete "/fr/m/#{invitation.token}/template"

      expect(response).to redirect_to("/fr/m/#{invitation.token}")
      expect(invitation.reload.template).to be_nil
      follow_redirect!
      expect(response.body).to include(I18n.t("mensurations.share.template_femme", locale: :fr))
      expect(response.body).to include(I18n.t("mensurations.share.template_homme", locale: :fr))
    end
  end

  describe "étapes" do
    before { open_otp_session }

    it "enregistre la progression à chaque étape sans finaliser" do
      patch_step(invitation, {
        step: "identity", direction: "next",
        mensuration: { prenom: "Anna", nom: "Durand", telephone: "0611111111" }
      })

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      mensuration = invitation.reload.mensuration
      expect(mensuration).to be_present
      expect(mensuration.prenom).to eq("Anna")
      expect(mensuration.draft_step).to eq("mesures.hauteur")
      expect(invitation.status).not_to eq("completed")
      expect(Client.count).to eq(0)
    end

    it "reprend le champ guidé et les mesures après rechargement" do
      patch_step(invitation, {
        step: "identity", direction: "next",
        mensuration: { prenom: "Anna", nom: "Durand" }
      })
      patch_step(invitation, {
        step: "mesures.hauteur", direction: "next",
        measurements: { hauteur: "168" }
      })

      get "/fr/m/#{invitation.token}"

      expect(response).to redirect_to("/fr/m/#{invitation.token}?step=mesures.vetements")
      follow_redirect!
      expect(response.body).to include('name="measurements[taille_soutien_gorge]"')
      expect(invitation.reload.mensuration.draft_step).to eq("mesures.vetements")
      expect(invitation.mensuration.value_for("hauteur")).to eq("168")
    end

    it "reprend le formulaire à la dernière étape sauvegardée" do
      patch_step(invitation, {
        step: "identity", direction: "next",
        mensuration: { prenom: "Anna", nom: "Durand" }
      })

      get "/fr/m/#{invitation.token}"

      expect(response).to redirect_to("/fr/m/#{invitation.token}?step=mesures.hauteur")
      follow_redirect!
      expect(response.body).to include('name="measurements[hauteur]"')
      expect(response.body).not_to include("mensuration-form__thanks")
    end

    it "redirige vers l'étape canonique si l'URL saute en avant" do
      patch_step(invitation, {
        step: "identity", direction: "next",
        mensuration: { prenom: "Anna", nom: "Durand" }
      })

      get "/fr/m/#{invitation.token}", params: { step: "photo" }

      expect(response).to redirect_to("/fr/m/#{invitation.token}?step=mesures.hauteur")
    end

    it "permet de revenir en arrière via l'URL tant que l'étape est atteinte" do
      patch_step(invitation, {
        step: "identity", direction: "next",
        mensuration: { prenom: "Anna", nom: "Durand" }
      })

      get "/fr/m/#{invitation.token}", params: { step: "identity" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="mensuration[prenom]"')
      expect(response.body).not_to include('name="measurements[hauteur]"')
    end

    it "expose la clé d'étape sur le turbo-frame pour la synchro URL" do
      get "/fr/m/#{invitation.token}", params: { step: "identity" }

      expect(response.body).to include('data-mensuration-step="identity"')
    end

    it "revient à l'étape précédente via turbo stream" do
      patch_step(invitation, {
        step: "identity", direction: "next",
        mensuration: { prenom: "Anna", nom: "Durand" }
      })
      patch_step(invitation, { step: "mesures.hauteur", direction: "back" })

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('value="identity"')
      expect(response.body).to include('data-mensuration-step="identity"')
      expect(response.body).to include(I18n.t("mensurations.form.identity_title", locale: :fr))
      expect(response.body).to include("turbo-frame id=\"mensuration_progress\"")
      expect(response.body).to include(I18n.t("mensurations.form.step", current: 1, total: 4, locale: :fr))
    end

    it "cumule les mesures au fil des sauvegardes" do
      patch "/fr/m/#{invitation.token}/step", params: {
        step: "identity", direction: "next",
        mensuration: { prenom: "Anna", nom: "Durand" }
      }
      patch "/fr/m/#{invitation.token}/step", params: {
        step: "mesures.hauteur", direction: "next",
        measurements: { hauteur: "168" }
      }
      patch "/fr/m/#{invitation.token}/step", params: {
        step: "mesures.vetements", direction: "next",
        mensuration: { prenom: "Anna", nom: "Durand" },
        measurements: { taille_soutien_gorge: "90D", taille_veste_chemisier: "38" }
      }

      mensuration = invitation.reload.mensuration
      expect(mensuration.draft_step).to eq("photo")
      expect(mensuration.measurements).to include("hauteur" => "168", "taille_soutien_gorge" => "90D")
    end

    it "refuse l'étape sans session OTP" do
      reset!
      patch "/fr/m/#{invitation.token}/step", params: {
        step: "identity", direction: "next",
        mensuration: { prenom: "Anna", nom: "Durand" }
      }

      expect(response).to redirect_to("/fr/m/#{invitation.token}")
      expect(Mensuration.count).to eq(0)
    end

    it "permet de reprendre un brouillon après une nouvelle vérification OTP" do
      patch_step(invitation, {
        step: "identity", direction: "next",
        mensuration: { prenom: "Anna", nom: "Durand" }
      })
      patch_step(invitation, {
        step: "mesures.hauteur", direction: "next",
        measurements: { hauteur: "168" }
      })

      reset!
      get "/fr/m/#{invitation.token}"
      expect(response.body).to include(I18n.t("mensurations.otp.code_label", locale: :fr))

      open_otp_session
      get "/fr/m/#{invitation.token}"

      expect(response).to redirect_to("/fr/m/#{invitation.token}?step=mesures.vetements")
      follow_redirect!
      expect(invitation.reload.mensuration.prenom).to eq("Anna")
      expect(invitation.mensuration.value_for("hauteur")).to eq("168")
    end

    it "retrouve la même invitation via la landing après brouillon" do
      patch_step(invitation, {
        step: "identity", direction: "next",
        mensuration: { prenom: "Anna", nom: "Durand" }
      })
      patch_step(invitation, {
        step: "mesures.hauteur", direction: "next",
        measurements: { hauteur: "168" }
      })

      reset!
      allow(RecaptchaVerifier).to receive(:verify).and_return(true)
      expect {
        post "/mensurations", params: {
          email: invitation.email, form_locale: "fr",
          "g-recaptcha-response" => "ok"
        }
      }.not_to change(MensurationInvitation, :count)

      expect(response).to redirect_to("/fr/m/#{invitation.token}")
      open_otp_session
      get "/fr/m/#{invitation.token}"

      expect(response).to redirect_to("/fr/m/#{invitation.token}?step=mesures.vetements")
      follow_redirect!
      expect(invitation.reload.mensuration.measurements).to eq("hauteur" => "168")
    end
  end

  describe "session OTP expirée" do
    include ActiveSupport::Testing::TimeHelpers

    it "refuse la sauvegarde et renvoie vers la page OTP" do
      travel_to Time.zone.local(2026, 6, 1, 12, 0, 0) do
        open_otp_session
        travel 3.hours

        post "/fr/m/#{invitation.token}/complete", params: {
          mensuration: { prenom: "Anna", nom: "Durand" },
          measurements: { hauteur: "168" }
        }

        expect(response).to redirect_to("/fr/m/#{invitation.token}")
        expect(Mensuration.count).to eq(0)

        follow_redirect!
        expect(response.body).to include(I18n.t("mensurations.otp.session_expired", locale: :fr))
        expect(response.body).to include(I18n.t("mensurations.otp.send_code", locale: :fr))
      end
    end
  end

  describe "parcours homme" do
    let!(:invitation_homme) do
      MensurationInvitation.create!(
        email: "homme@example.com", template: "homme", locale: "fr",
        prenom: "Jean", nom: "Martin"
      )
    end

    before do
      code = invitation_homme.generate_otp!
      post "/fr/m/#{invitation_homme.token}/verify", params: { code: code }
    end

    it "enregistre tailles vêtement et mensurations au mètre" do
      patch "/fr/m/#{invitation_homme.token}/step",
            params: { step: "identity", direction: "next",
                      mensuration: { prenom: "Jean", nom: "Martin", telephone: "0612345678" } }
      patch "/fr/m/#{invitation_homme.token}/step",
            params: { step: "tailles", direction: "next",
                      measurements: { taille_veste: "50", taille_chemise: "41" } }
      patch "/fr/m/#{invitation_homme.token}/step",
            params: { step: "corps.hauteur", direction: "next", measurements: { hauteur: "182" } }
      patch "/fr/m/#{invitation_homme.token}/step",
            params: { step: "corps.tour_cou", direction: "next", measurements: { tour_cou: "40" } }
      patch "/fr/m/#{invitation_homme.token}/step",
            params: { step: "corps.largeur_epaules", direction: "next", measurements: { largeur_epaules: "48" } }
      patch "/fr/m/#{invitation_homme.token}/step",
            params: { step: "corps.tour_poitrine", direction: "next", measurements: { tour_poitrine: "100" } }
      patch "/fr/m/#{invitation_homme.token}/step",
            params: { step: "corps.tour_taille", direction: "next", measurements: { tour_taille: "84" } }
      patch "/fr/m/#{invitation_homme.token}/step",
            params: { step: "corps.tour_hanches", direction: "next", measurements: { tour_hanches: "98" } }
      patch "/fr/m/#{invitation_homme.token}/step",
            params: { step: "corps.longueur_bras_ext", direction: "next", measurements: { longueur_bras_ext: "62" } }

      expect {
        post "/fr/m/#{invitation_homme.token}/complete"
      }.to change(Client, :count).by(1)

      mensuration = invitation_homme.reload.mensuration
      expect(mensuration).to be_persisted
      expect(mensuration.template).to eq("homme")
      expect(mensuration.measurements).to include(
        "taille_veste" => "50",
        "taille_chemise" => "41",
        "hauteur" => "182",
        "tour_cou" => "40",
        "largeur_epaules" => "48",
        "tour_poitrine" => "100",
        "tour_taille" => "84",
        "tour_hanches" => "98",
        "longueur_bras_ext" => "62"
      )
      expect(mensuration.value_for("taille_soutien_gorge")).to be_nil
      expect(invitation_homme.status).to eq("completed")

      follow_redirect!
      expect(response.body).to include("mensuration-form__thanks")
    end
  end

  describe "sauvegarde" do
    before { open_otp_session }

    it "enregistre la fiche, ne garde que les champs du template et crée le client" do
      expect {
        complete_femme_form
      }.to change(Mensuration, :count).by(1).and change(Client, :count).by(1)

      mensuration = Mensuration.last
      expect(mensuration.measurements).to eq(
        "hauteur" => "168",
        "taille_soutien_gorge" => "90D",
        "taille_veste_chemisier" => "38"
      )
      # tour_cou est un champ homme : ignoré sur une invitation femme.
      expect(mensuration.value_for("tour_cou")).to be_nil
      expect(mensuration.client.mail).to eq("cliente@example.com")
      expect(invitation.reload.status).to eq("completed")

      follow_redirect!
      expect(response.body).to include("mensuration-card-header")
      expect(response.body).to include("mensuration-form__thanks")
      expect(response.body).to include(I18n.t("mensurations.form.thanks_title", locale: :fr))
      expect(response.body).to include(I18n.t("mensurations.form.show_answers", locale: :fr))
      expect(response.body).to include("edit=1")
      expect(response.body).to include("mensuration-delete-link")
      expect(response.body).not_to include("btn-outline-danger")
      expect(response.body).not_to include("form-reveal")
      expect(response.body).not_to include("measure-guide")
    end

    it "rattache au client existant si l'e-mail correspond" do
      existing = Client.create!(nom: "Martin", mail: "cliente@example.com", tel: "0400000000")

      complete_femme_form

      expect(Mensuration.last.client).to eq(existing)
      expect(existing.reload.tel).to eq("0400000000")
      expect(existing.nom).to eq("Martin")
    end

    it "n'accepte pas un nom déjà connu ni un e-mail envoyés dans le POST" do
      complete_femme_form

      mensuration = Mensuration.last
      expect(mensuration.nom).to eq("Durand")
      expect(mensuration.client.mail).to eq("cliente@example.com")
    end

    it "accepte le nom s'il n'était pas encore renseigné, puis le verrouille" do
      invitation.update!(nom: nil)

      patch "/fr/m/#{invitation.token}/step",
            params: { step: "identity", direction: "next", mensuration: { prenom: "Anna", nom: "Durand" } }
      patch "/fr/m/#{invitation.token}/step",
            params: { step: "mesures.hauteur", direction: "next", measurements: { hauteur: "168" } }
      patch "/fr/m/#{invitation.token}/step", params: {
        step: "mesures.vetements", direction: "next",
        measurements: { taille_soutien_gorge: "90D", taille_veste_chemisier: "38" }
      }
      post "/fr/m/#{invitation.token}/complete"
      expect(Mensuration.last.nom).to eq("Durand")

      patch "/fr/m/#{invitation.token}/step",
            params: { step: "identity", direction: "next", mensuration: { prenom: "Anna", nom: "Martin" } }
      expect(Mensuration.last.reload.nom).to eq("Durand")
    end

    it "supprime la fiche à la demande du client" do
      complete_femme_form

      expect {
        delete "/fr/m/#{invitation.token}"
      }.to change(Mensuration, :count).by(-1)

      expect(invitation.reload.status).to eq("verified")
      expect(invitation.template).to be_nil
    end

    it "attache une photo en pied JPEG" do
      photo = Rack::Test::UploadedFile.new(mensuration_jpeg_path, "image/jpeg", true)

      advance_through_femme_form
      post "/fr/m/#{invitation.token}/complete", params: { photo_pied: photo }

      mensuration = Mensuration.last
      expect(mensuration.photo_pied).to be_attached
      expect(mensuration.photo_pied.filename.to_s).to eq("pied.jpg")
      expect(mensuration.photo_pied.content_type).to eq("image/jpeg")
    end

    it "refuse une photo qui n'est pas une image" do
      file = Tempfile.new(["notes", ".txt"])
      file.write("pas une image")
      file.rewind

      advance_through_femme_form
      post "/fr/m/#{invitation.token}/complete",
           params: { photo_pied: Rack::Test::UploadedFile.new(file.path, "text/plain") }

      expect(Mensuration.count).to eq(1)
      expect(invitation.reload.status).not_to eq("completed")
      expect(response).to redirect_to("/fr/m/#{invitation.token}?step=photo")
      follow_redirect!
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

      patch "/en/m/#{invitation_en.token}/step", params: {
        step: "identity", direction: "next",
        mensuration: { prenom: "John", nom: "Smith" }
      }
      patch "/en/m/#{invitation_en.token}/step", params: {
        step: "tailles", direction: "next",
        measurements: { taille_veste: "48", taille_chemise: "39" }
      }
      patch "/en/m/#{invitation_en.token}/step", params: {
        step: "corps.hauteur", direction: "next",
        measurements: { hauteur: "180" }
      }

      get "/en/m/#{invitation_en.token}", params: { step: "corps.tour_cou" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("mensurations.share.welcome", locale: :en))
      expect(response.body).to include(I18n.t("mensurations.fields.tour_cou.label", locale: :en))
      expect(response.body).to include('data-controller="figure-ruler"')
      expect(response.body).to include('mensuration-guide__figure-stage')
      expect(response.body).to include("/images/human_body.svg")
      expect(response.body).to include('data-figure-ruler-clip-value="neck"')
      expect(response.body).to include(I18n.t("mensurations.fields.tour_cou.advice", locale: :en))
    end
  end
end
