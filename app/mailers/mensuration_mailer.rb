class MensurationMailer < ApplicationMailer
  layout "mailer"

  # Code de vérification : reçu en clair ici uniquement, seul le hash est en base.
  def otp_code(invitation, code)
    @invitation = invitation
    @code = code

    I18n.with_locale(@invitation.locale.presence || :fr) do
      attach_inline_logo

      mail(to: invitation.email, subject: I18n.t("mensurations.mailer.otp.subject")) do |format|
        format.html { render template: "admin/mensuration_mailer/otp_code", layout: "mailer" }
        format.text { render template: "admin/mensuration_mailer/otp_code" }
      end
    end
  end
end
