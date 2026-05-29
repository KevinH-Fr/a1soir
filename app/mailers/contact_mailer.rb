class ContactMailer < ApplicationMailer
  layout "mailer"

  def contact_form(contact_message)
    @contact_message = contact_message
    return unless @contact_message&.email.present?

    admin_email = ENV['GMAIL_ACCOUNT']
    return unless admin_email.present?

    I18n.locale = :fr

    attach_inline_logo

    subject = "Nouveau message de contact - #{@contact_message.sujet.presence || 'Sans sujet'}"

    mail(to: admin_email, subject: subject) do |format|
      format.html { render template: "public/contact_mailer/contact_form", layout: "mailer" }
      format.text { render template: "public/contact_mailer/contact_form" }
    end
  end
end
