class CommandeMailer < ApplicationMailer

    def email_commande(doc_edition, pdf_data)


        @message_full = doc_edition.message 

        # Add your footer content
        footer = 
        "Autour d'un soir - Cannes
        \n 04 93 00 00 00
        \n https://example.com "

        @message_full += "\n\n#{footer}"
 
        attachments["#{doc_edition.doc_type}_#{doc_edition.commande.ref_commande}.pdf"] = pdf_data
    
        mail(to: doc_edition.destinataire, subject: doc_edition.sujet, body: @message_full) 
    
    end

   

    
end
