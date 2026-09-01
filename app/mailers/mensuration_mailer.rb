class MensurationMailer < ApplicationMailer
  layout "mailer"

  # Lien d'invitation vers /m/:token, dans la langue choisie à l'invitation.
  def invitation(invitation)
    @invitation = invitation
    @url = mensuration_link(invitation)

    I18n.with_locale(invitation.locale) do
      attach_inline_logo

      mail(to: invitation.email, subject: I18n.t("mensurations.mailer.invitation.subject")) do |format|
        format.html { render template: "admin/mensuration_mailer/invitation", layout: "mailer" }
        format.text { render template: "admin/mensuration_mailer/invitation" }
      end
    end
  end

  # Code de vérification : reçu en clair ici uniquement, seul le hash est en base.
  def otp_code(invitation, code)
    @invitation = invitation
    @code = code

    I18n.with_locale(invitation.locale) do
      attach_inline_logo

      mail(to: invitation.email, subject: I18n.t("mensurations.mailer.otp.subject")) do |format|
        format.html { render template: "admin/mensuration_mailer/otp_code", layout: "mailer" }
        format.text { render template: "admin/mensuration_mailer/otp_code" }
      end
    end
  end

  private

  # Le default_url_options mailer pointe sur l'hôte admin : le lien client vise le site public.
  def mensuration_link(invitation)
    if Rails.env.production?
      mensuration_url(token: invitation.token, locale: invitation.locale,
                      host: ENV.fetch("PUBLIC_APP_HOST", "a1soir.com"), protocol: "https")
    else
      mensuration_url(token: invitation.token, locale: invitation.locale,
                      host: "localhost", port: 3000, protocol: "http")
    end
  end
end
