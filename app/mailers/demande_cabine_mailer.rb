class DemandeCabineMailer < ApplicationMailer

  layout "mailer"

  def confirmation_client(demande)
    @demande = demande

    # Le champ email du modèle est `mail`
    return unless @demande&.mail.present?

    I18n.locale = :fr

    # Inline logo for consistency with other mailers
    logo_path = Rails.root.join('app/assets/images/logo_a1soir_2025.png')
    attachments.inline['logo_a1soir_2025.png'] = File.read(logo_path) if File.exist?(logo_path)

    subject = I18n.t('demande_cabine.confirmation_client.subject', default: "Votre demande d’essayage")

    mail(to: @demande.mail, subject: subject) do |format|
      format.html { render template: "public/demande_cabine_mailer/confirmation_client", layout: "mailer" }
      format.text { render template: "public/demande_cabine_mailer/confirmation_client" }
    end
  end

  def notification_admin(demande)
    @demande = demande

    admin_email = ENV['GMAIL_ACCOUNT']
    return unless admin_email.present?

    I18n.locale = :fr

    logo_path = Rails.root.join('app/assets/images/logo_a1soir_2025.png')
    attachments.inline['logo_a1soir_2025.png'] = File.read(logo_path) if File.exist?(logo_path)

    subject = I18n.t('demande_cabine.notification_admin.subject', default: "Nouvelle demande d’essayage")

    mail(to: admin_email, subject: subject) do |format|
      format.html { render template: "public/demande_cabine_mailer/notification_admin", layout: "mailer" }
      format.text { render template: "public/demande_cabine_mailer/notification_admin" }
    end
  end

end


