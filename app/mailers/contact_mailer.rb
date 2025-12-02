class ContactMailer < ApplicationMailer
  layout "mailer"

  def contact_form(contact_message)
    @contact_message = contact_message
    return unless @contact_message&.email.present?

    admin_email = ENV['GMAIL_ACCOUNT']
    return unless admin_email.present?

    I18n.locale = :fr

    logo_path = Rails.root.join('app/assets/images/logo_a1soir_2025.png')
    attachments.inline['logo_a1soir_2025.png'] = File.read(logo_path) if File.exist?(logo_path)

    subject = "Nouveau message de contact - #{@contact_message.sujet.presence || 'Sans sujet'}"

    mail(to: admin_email, subject: subject) do |format|
      format.html { render template: "public/contact_mailer/contact_form", layout: "mailer" }
      format.text { render template: "public/contact_mailer/contact_form" }
    end
  end
end

