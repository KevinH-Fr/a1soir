module Public
  # Formulaire mensurations : landing publique /mensurations, puis /m/:token (OTP).
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
    before_action :require_otp_session, only: [:update_step, :complete, :destroy, :update_template, :reset_template]
    before_action :load_mensuration_flow, only: [:show, :update_step, :complete]

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

    def show
      if otp_session_valid?
        redirect_to canonical_step_url and return if step_url_correction_needed?

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
        redirect_to mensuration_path(token: @invitation.token, edit: 1, step: Mensuration::Flow::IDENTITY)
      else
        redirect_to mensuration_path(token: @invitation.token, step: Mensuration::Flow::IDENTITY)
      end
    end

    def reset_template
      if @invitation.completed?
        redirect_to mensuration_path(token: @invitation.token)
        return
      end

      @invitation.update!(template: nil)
      redirect_to mensuration_path(token: @invitation.token)
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

    def update_step
      unless @invitation.preferences_chosen?
        redirect_to mensuration_path(token: @invitation.token), alert: t("mensurations.share.choose_preferences")
        return
      end

      @step = @flow.step(params[:step])

      if params[:direction] == "back"
        target_step = @flow.previous(@step) || @step
        @mensuration.update_column(:draft_step, target_step.key) if @mensuration.persisted?
        respond_to do |format|
          format.turbo_stream { render_step_transition(target_step) }
          format.html { redirect_to mensuration_path(token: @invitation.token, step: target_step.key) }
        end
        return
      end

      unless @mensuration.save_step!(@step, identity: identity_params, measurements: permitted_measurements,
                                     advance_to: @flow.next(@step)&.key)
        render_step_errors
        return
      end

      next_step = @flow.next(@step)
      respond_to do |format|
        format.turbo_stream { render_step_transition(next_step) }
        format.html do
          redirect_to mensuration_path(token: @invitation.token, step: next_step&.key || @step.key)
        end
      end
    end

    def complete
      unless @invitation.preferences_chosen?
        redirect_to mensuration_path(token: @invitation.token), alert: t("mensurations.share.choose_preferences")
        return
      end

      @step = @flow.step(Mensuration::Flow::PHOTO)
      @mensuration.apply_complete_input(photo: params[:photo_pied])

      if @mensuration.complete!
        redirect_to mensuration_path(token: @invitation.token), status: :see_other
      else
        @mensuration.reload if @mensuration.persisted?
        redirect_to mensuration_path(
          token: @invitation.token,
          **{ step: Mensuration::Flow::PHOTO, edit: (@editing ? 1 : nil) }.compact
        ), alert: @mensuration.errors.full_messages.to_sentence
      end
    end

    def destroy
      @invitation.clear_mensuration!
      redirect_to mensuration_path(token: @invitation.token), notice: t("mensurations.form.deleted")
    end

    private

    def load_mensuration_flow
      return unless otp_session_valid?

      @mensuration = @invitation.mensuration || @invitation.build_public_mensuration
      return unless @invitation.template.present?

      @editing = editing_request?
      return if @invitation.completed? && !@editing

      @flow = Mensuration::Flow.new(@invitation, @mensuration)
      @step = resolve_step
    end

    def editing_request?
      return true if params[:edit].present?

      @invitation.completed? && action_name.in?(%w[update_step complete])
    end

    def resolve_step
      key = if params[:resume] == "identity"
              Mensuration::Flow::IDENTITY
            elsif params[:step].present?
              params[:step]
            end

      requested = @flow.step(key)
      return requested if step_reachable?(requested)

      @flow.step(@mensuration.draft_step)
    end

    def step_reachable?(step)
      return true if editing_request?
      return step.first? if @mensuration.draft_step.blank?

      resume = @flow.step(@mensuration.draft_step)
      step.position <= resume.position
    end

    def step_url_correction_needed?
      return false unless @flow
      return false if @invitation.completed? && !@editing

      params[:step].blank? || (!editing_request? && @flow.step(params[:step]).key != @step.key)
    end

    def canonical_step_url
      options = { step: @step.key }
      options[:edit] = 1 if @editing
      mensuration_path(token: @invitation.token, **options)
    end

    def render_step_transition(step)
      @step = step
      response.set_header("X-Mensuration-Step", @step.key)
      render turbo_stream: [
        turbo_stream.replace("mensuration_step", partial: "public/mensurations/step_frame", locals: step_locals),
        turbo_stream.replace("mensuration_progress", partial: "public/mensurations/progress_frame",
                              locals: { flow: @flow, step: @step })
      ]
    end

    def render_step_errors
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("mensuration_step",
                                                    partial: "public/mensurations/step_frame",
                                                    locals: step_locals),
                 status: :unprocessable_entity
        end
        format.html { render :form, status: :unprocessable_entity }
      end
    end

    def step_partial
      "public/mensurations/steps/#{ @step.partial }"
    end

    def step_locals
      { step: @step, mensuration: @mensuration, invitation: @invitation, editing: @editing, flow: @flow }
    end

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

    def load_footer_texte
      texte = Texte.last
      return unless texte

      @footer_texte_adresse = texte.adresse&.to_plain_text.presence
      @footer_texte_contact = texte.contact&.to_plain_text.presence
    end

    def set_invitation
      @invitation = MensurationInvitation.find_by(token: params[:token])
      return if @invitation&.usable?

      render "errors/not_found", layout: "error", status: :not_found
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
