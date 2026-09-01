module Public
  # Formulaire mensurations sur invitation (/m/:token).
  # Hérite directement d'ActionController::Base : pas de panier ni de HTTP Basic boutique
  # (Public::ApplicationController) — le client arrive ici uniquement via le lien reçu par mail.
  class MensurationsController < ActionController::Base
    layout "mensuration"

    SESSION_KEY = "mensuration_auth".freeze
    SESSION_TTL = 2.hours

    before_action :set_locale
    before_action :set_invitation
    before_action :require_otp_session, only: [:save, :destroy]

    # Page unique : demande de code tant que l'e-mail n'est pas vérifié, formulaire ensuite.
    def show
      if otp_session_valid?
        @mensuration = @invitation.mensuration || build_mensuration
        render :form
      else
        render :otp
      end
    end

    def send_otp
      unless @invitation.otp_resend_allowed?
        redirect_to mensuration_path(token: @invitation.token), alert: t("mensurations.otp.resend_wait")
        return
      end

      code = @invitation.generate_otp!
      MensurationMailer.otp_code(@invitation, code).deliver_later
      redirect_to mensuration_path(token: @invitation.token), notice: t("mensurations.otp.code_sent")
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

    def save
      @mensuration = @invitation.mensuration || build_mensuration
      @mensuration.assign_attributes(identity_params)
      @mensuration.measurements = measurements_params
      # Affectation (pas .attach) : l'upload n'est persisté qu'au save, après validation.
      @mensuration.photo_pied = params[:photo_pied] if params[:photo_pied].present?

      if @mensuration.save
        @mensuration.resolve_and_link_client!
        @invitation.update!(status: "completed")
        redirect_to mensuration_path(token: @invitation.token), notice: t("mensurations.form.saved")
      else
        flash.now[:alert] = @mensuration.errors.full_messages.to_sentence
        render :form, status: :unprocessable_entity
      end
    end

    def destroy
      @invitation.mensuration&.destroy
      @invitation.update!(status: "verified")
      redirect_to mensuration_path(token: @invitation.token), notice: t("mensurations.form.deleted")
    end

    private

    def set_locale
      requested_locale = params[:locale]&.to_sym
      I18n.locale = I18n.available_locales.include?(requested_locale) ? requested_locale : I18n.default_locale
    end

    def default_url_options
      { locale: I18n.locale }
    end

    # 404 générique : ne pas révéler si un token a existé / est expiré.
    def set_invitation
      @invitation = MensurationInvitation.find_by(token: params[:token])
      raise ActiveRecord::RecordNotFound if @invitation.nil? || @invitation.expired?
    end

    def build_mensuration
      @invitation.build_mensuration(
        template: @invitation.template,
        locale: @invitation.locale,
        prenom: @invitation.prenom,
        nom: @invitation.nom
      )
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

    def identity_params
      params.fetch(:mensuration, {}).permit(:prenom, :nom, :telephone, :adresse, :cp, :ville, :date_evenement)
    end

    # Seules les clés déclarées dans le YAML du template sont conservées.
    def measurements_params
      allowed = Mensuration.fields_for(@invitation.template).map { |f| f["key"] }
      raw = params.fetch(:measurements, {}).permit(*allowed)
      raw.to_h.transform_values { |v| v.to_s.strip }.compact_blank
    end
  end
end
