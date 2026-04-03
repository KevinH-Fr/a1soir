# frozen_string_literal: true

class StripePaymentMailer < ApplicationMailer
  layout "mailer"

  LOGO_FILENAME = "logo_a1soir_2025.png"

  def confirmation(stripe_payment)
    @payment = stripe_payment
    @items = stripe_payment.stripe_payment_items.includes(:produit)
    return if @payment.customer_email.blank?

    I18n.locale = @payment.commande&.client&.language || :fr

    assign_public_url_helpers

    attach_logo_if_present

    subject = I18n.t("stripe_payment_mailer.confirmation.subject")

    mail(to: @payment.customer_email, subject: subject) do |format|
      format.html { render template: "admin/stripe_payment_mailer/confirmation", layout: "mailer" }
      format.text { render template: "admin/stripe_payment_mailer/confirmation" }
    end
  end

  def expedition(commande)
    @commande = commande
    @payment = commande.stripe_payment
    return if @payment&.customer_email.blank?

    @items = @payment.stripe_payment_items.includes(:produit)
    @numero_suivi = commande.numero_suivi
    @tracking_url = "https://www.laposte.fr/outils/suivre-vos-envois?code=#{@numero_suivi}" if @numero_suivi.present?

    I18n.locale = commande.client&.language || :fr

    assign_public_url_helpers

    attach_logo_if_present

    subject = I18n.t("stripe_payment_mailer.expedition.subject")

    mail(to: @payment.customer_email, subject: subject) do |format|
      format.html { render template: "admin/stripe_payment_mailer/expedition", layout: "mailer" }
      format.text { render template: "admin/stripe_payment_mailer/expedition" }
    end
  end

  def notification_admin(stripe_payment)
    @payment = stripe_payment
    @items = stripe_payment.stripe_payment_items.includes(:produit)

    admin_email = ENV["GMAIL_ACCOUNT"]
    return if admin_email.blank?

    I18n.locale = :fr

    assign_public_url_helpers
    @commande_admin_url = if @payment.commande.present?
                            admin_commande_url(@payment.commande, **admin_mailer_url_options)
                          end

    attach_logo_if_present

    subject = I18n.t("stripe_payment_mailer.notification_admin.subject")

    mail(to: admin_email, subject: subject) do |format|
      format.html { render template: "admin/stripe_payment_mailer/notification_admin", layout: "mailer" }
      format.text { render template: "admin/stripe_payment_mailer/notification_admin" }
    end
  end

  private

  def assign_public_url_helpers
    @public_site_url_options = public_site_url_options
    @blob_rails_host = Rails.env.production? ? "a1soir-2-2a03802389d6.herokuapp.com" : "localhost:3000"
    @blob_rails_protocol = Rails.env.production? ? "https" : "http"
  end

  def public_site_url_options
    if Rails.env.production?
      { host: "a1soir.com", protocol: "https" }
    else
      { host: "localhost", port: 3000, protocol: "http" }
    end
  end

  def admin_mailer_url_options
    if Rails.env.development?
      { host: "admin.lvh.me", port: 3000, protocol: "http" }
    else
      { host: ENV.fetch("ADMIN_MAILER_HOST", "admin.a1soir.com"), protocol: "https" }
    end
  end

  def attach_logo_if_present
    logo_path = Rails.root.join("app/assets/images/#{LOGO_FILENAME}")
    attachments.inline[LOGO_FILENAME] = File.read(logo_path) if File.exist?(logo_path)
  end
end
