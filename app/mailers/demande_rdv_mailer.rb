class DemandeRdvMailer < ApplicationMailer
  layout "mailer"

  def confirmation_client(demande_rdv)
    @demande_rdv = demande_rdv
    return unless @demande_rdv&.email.present?

    I18n.locale = :fr

    attach_inline_logo

    subject = I18n.t('demande_rdv.confirmation_client.subject')

    mail(to: @demande_rdv.email, subject: subject) do |format|
      format.html { render template: "admin/demande_rdv_mailer/confirmation_client", layout: "mailer" }
      format.text { render template: "admin/demande_rdv_mailer/confirmation_client" }
    end
  end

  def notification_admin(demande_rdv)
    @demande_rdv = demande_rdv
    @demande_cabine_essayage = demande_rdv.demande_cabine_essayage

    admin_email = ENV['GMAIL_ACCOUNT']
    return unless admin_email.present?

    I18n.locale = :fr

    attach_inline_logo

    subject = I18n.t('demande_rdv.notification_admin.subject')

    mail(to: admin_email, subject: subject) do |format|
      format.html { render template: "admin/demande_rdv_mailer/notification_admin", layout: "mailer" }
      format.text { render template: "admin/demande_rdv_mailer/notification_admin" }
    end
  end

end
