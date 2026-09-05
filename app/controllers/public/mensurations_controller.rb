module Public
  # Formulaire mensurations : landing publique /mensurations, puis /m/:token (OTP).
  # Hérite directement d'ActionController::Base : pas de panier ni de HTTP Basic boutique.
  class MensurationsController < ActionController::Base
    layout "mensuration"
    helper MensurationsHelper

    SESSION_KEY = "mensuration_auth".freeze
    SESSION_TTL = 2.hours
    START_RATE_LIMIT = 5
    START_RATE_WINDOW = 1.minute

    before_action :set_locale
    before_action :deny_indexing
    before_action :set_invitation, except: [:gate, :start]
    before_action :sync_invitation_locale, except: [:gate, :start]
    before_action :load_footer_texte
    before_action :require_otp_session, only: [:save, :draft, :destroy, :update_template]

    def gate
      @email = ""
      @form_locale = I18n.locale.to_s
      render :gate
    end

    def start
      @email = start_email
      @form_locale = start_form_locale || I18n.locale.to_s.presence_in(%w[fr en])

      unless RecaptchaVerifier.verify(params["g-recaptcha-response"], request.remote_ip)
        flash.now[:alert] = t("mensurations.share.recaptcha_required")
        render :gate, status: :unprocessable_entity
        return
      end

      unless @email.present? && @form_locale.present?
        flash.now[:alert] = t("mensurations.share.invalid")
        render :gate, status: :unprocessable_entity
        return
      end

      if share_start_rate_limited?(@email)
        flash.now[:alert] = t("mensurations.share.rate_limited")
        render :gate, status: :unprocessable_entity
        return
      end

      invitation = MensurationInvitation.find_or_prepare_for_share!(
        email: @email, locale: @form_locale
      )

      if invitation.deliver_otp!
        redirect_to_invitation(invitation, notice: t("mensurations.otp.code_sent"))
      else
        redirect_to_invitation(invitation, alert: t("mensurations.otp.resend_wait"))
      end
    end

    # Page unique : demande de code tant que l'e-mail n'est pas vérifié, formulaire ensuite.
    def show
      if otp_session_valid?
        @mensuration = @invitation.mensuration || @invitation.build_public_mensuration
        @editing = @invitation.completed? && params[:edit].present?
        @wizard_index = wizard_start_index
        render :form
      else
        render :otp
      end
    end

    def update_template
      template = params[:template].to_s.presence_in(MensurationInvitation::TEMPLATES)
      unless template
        redirect_to mensuration_path(token: @invitation.token),
                    alert: t("mensurations.share.choose_preferences")
        return
      end

      @invitation.apply_template!(template)
      if @invitation.completed?
        redirect_to mensuration_path(token: @invitation.token, edit: 1, resume: "identity")
      else
        redirect_to mensuration_path(token: @invitation.token, resume: "identity")
      end
    end

    def send_otp
      if @invitation.deliver_otp!
        redirect_to mensuration_path(token: @invitation.token), notice: t("mensurations.otp.code_sent")
      else
        redirect_to mensuration_path(token: @invitation.token), alert: t("mensurations.otp.resend_wait")
      end
    end

    def verify_otp
      if @invitation.verify_otp(params[:code])
        open_otp_session
        redirect_to mensuration_path(token: @invitation.token)
      else
        key = @invitation.otp_attempts >= MensurationInvitation::OTP_MAX_ATTEMPTS ? :too_many_attempts : :invalid_code
        redirect_to mensuration_path(token: @invitation.token), alert: t("mensurations.otp.#{key}")
      end
    end

    def draft
      unless @invitation.preferences_chosen?
        head :unprocessable_entity
        return
      end

      wizard_index = params[:wizard_index].to_i
      if wizard_index < 1
        head :unprocessable_entity
        return
      end

      @mensuration = @invitation.mensuration || @invitation.build_public_mensuration
      @mensuration.apply_public_input(
        identity: identity_params,
        measurements: permitted_measurements
      )

      if @mensuration.save_draft!(wizard_index: wizard_index)
        head :no_content
      else
        head :unprocessable_entity
      end
    end

    def save
      unless @invitation.preferences_chosen?
        redirect_to mensuration_path(token: @invitation.token), alert: t("mensurations.share.choose_preferences")
        return
      end

      @mensuration = @invitation.mensuration || @invitation.build_public_mensuration
      @mensuration.apply_public_input(
        identity: identity_params,
        measurements: permitted_measurements,
        photo: params[:photo_pied]
      )

      if @mensuration.complete!
        redirect_to mensuration_path(token: @invitation.token)
      else
        @editing = @invitation.completed? || params[:edit].present?
        @wizard_index = wizard_start_index
        flash.now[:alert] = @mensuration.errors.full_messages.to_sentence
        render :form, status: :unprocessable_entity
      end
    end

    def destroy
      @invitation.clear_mensuration!
      redirect_to mensuration_path(token: @invitation.token), notice: t("mensurations.form.deleted")
    end

    private

    def set_locale
      requested = params[:locale].to_s
      if %w[fr en].include?(requested)
        session[:mensuration_locale] = requested
        I18n.locale = requested.to_sym
      elsif %w[fr en].include?(session[:mensuration_locale].to_s)
        I18n.locale = session[:mensuration_locale].to_sym
      else
        I18n.locale = I18n.default_locale
      end
    end

    def sync_invitation_locale
      @invitation&.sync_locale!(I18n.locale, persist_on_fiche: otp_session_valid?)
    end

    def redirect_to_invitation(invitation, **flash)
      redirect_to mensuration_path(token: invitation.token, locale: invitation.locale.presence || "fr"),
                  **flash
    end

    def default_url_options
      return {} if params[:token].blank?

      { locale: I18n.locale }
    end

    def deny_indexing
      response.set_header("X-Robots-Tag", "noindex, nofollow, noarchive")
    end

    # Coordonnées boutique pour le pied de page (même source que le footer public).
    def load_footer_texte
      texte = Texte.last
      return unless texte

      @footer_texte_adresse = texte.adresse&.to_plain_text.presence
      @footer_texte_contact = texte.contact&.to_plain_text.presence
    end

    # 404 boutique (même page qu'un token inconnu ou expiré). Render direct :
    # en local, raise RecordNotFound affiche la page d'erreur Rails, pas la 404.
    def set_invitation
      @invitation = MensurationInvitation.find_by(token: params[:token])
      return if @invitation&.usable?

      render "errors/not_found", layout: "error", status: :not_found
    end

    def wizard_start_index
      if @invitation.completed?
        return 1 if params[:resume] == "identity" || @editing

        return 0
      end

      return 1 if params[:resume] == "identity"
      return @mensuration.draft_wizard_index if @mensuration&.draft_wizard_index.present?

      0
    end

    def start_email
      email = params[:email].to_s.strip.downcase.presence
      return nil unless email&.match?(URI::MailTo::EMAIL_REGEXP)

      email
    end

    def start_form_locale
      params[:form_locale].to_s.presence_in(%w[fr en])
    end

    def share_start_rate_limited?(email)
      keys = [share_rate_key("ip", request.remote_ip), share_rate_key("email", email)]
      return true if keys.any? { |key| Rails.cache.read(key).to_i >= START_RATE_LIMIT }

      keys.each { |key| Rails.cache.write(key, Rails.cache.read(key).to_i + 1, expires_in: START_RATE_WINDOW) }
      false
    end

    def share_rate_key(kind, value)
      "mensuration_share_start/#{kind}/#{value}"
    end

    # ---- Session courte après vérification OTP -----------------------------

    def open_otp_session
      session[SESSION_KEY] = { "id" => @invitation.id, "exp" => SESSION_TTL.from_now.to_i }
    end

    def otp_session_valid?
      data = session[SESSION_KEY]
      data.is_a?(Hash) && data["id"] == @invitation.id && Time.current.to_i < data["exp"].to_i
    end

    def require_otp_session
      return if otp_session_valid?

      redirect_to mensuration_path(token: @invitation.token), alert: t("mensurations.otp.session_expired")
    end

    # ---- Params -------------------------------------------------------------

    # Nom : saisi une seule fois. S'il est déjà sur l'invitation ou la fiche, on ignore le POST.
    helper_method :mensuration_nom_locked?

    def mensuration_nom_locked?
      return true if @invitation.nom.present?

      @mensuration.persisted? && @mensuration.nom.present?
    end

    def identity_params
      permitted = [:prenom, :telephone, :adresse, :cp, :ville, :date_evenement]
      permitted << :nom unless mensuration_nom_locked?
      params.fetch(:mensuration, {}).permit(*permitted)
    end

    def permitted_measurements
      params.fetch(:measurements, {}).permit(*Mensuration.field_keys_for(@invitation.template))
    end
  end
end
