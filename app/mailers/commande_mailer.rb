class CommandeMailer < ApplicationMailer

  layout "mailer"  # This tells Rails to use app/views/layouts/mailer.html.erb

  def email_commande(doc_edition, pdf_data)
    @message_full = doc_edition.message
    @doc_edition = doc_edition
  
    I18n.locale = @doc_edition.commande.client.language || :fr 

    attachments["#{doc_edition.doc_type}_#{doc_edition.commande.ref_commande}.pdf"] = pdf_data

    attachments.inline['logo_a1soir_2025.png'] = File.read(Rails.root.join('app/assets/images/logo_a1soir_2025.png'))

    mail(to: doc_edition.destinataire, subject: doc_edition.sujet, body: @message_full) do |format|
      format.html { render layout: "mailer" }  # Force HTML and layout
    end

  end

end
  