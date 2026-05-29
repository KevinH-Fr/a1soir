class CommandeMailer < ApplicationMailer

  layout "mailer"  # This tells Rails to use app/views/layouts/mailer.html.erb

  def email_commande(doc_edition, pdf_data)
    @message_full = doc_edition.message
    @doc_edition = doc_edition

    I18n.locale = @doc_edition.commande.client.language || :fr

    attachments["#{doc_edition.doc_type}_#{doc_edition.commande.ref_commande}.pdf"] = pdf_data

    attach_inline_logo

    mail(to: doc_edition.destinataire, subject: doc_edition.sujet, body: @message_full) do |format|
      format.html { render template: "admin/commande_mailer/email_commande", layout: "mailer" }
    end

  end

  def confirmation_restitution(commande)
    @commande = commande
    @client = commande.client

    I18n.locale = @client.language || :fr

    attach_inline_logo

    subject = I18n.t('restitution_email.subject', ref_commande: @commande.ref_commande)

    mail(to: @client.mail, subject: subject) do |format|
      format.html { render template: "admin/commande_mailer/confirmation_restitution", layout: "mailer" }
    end
  end

end
