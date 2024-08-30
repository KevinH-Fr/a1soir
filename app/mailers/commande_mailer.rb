class CommandeMailer < ApplicationMailer

    def email_commande(doc_edition, pdf_data)


        @message_full = doc_edition.message 

        next_meeting =         
            if doc_edition.commande.meetings.where('datedebut > ?', DateTime.now).exists?
                "\n
                Prochain RDV:
                \n
                #{doc_edition.commande.meetings.first.start_time.strftime("%d/%m/%y" " à %H:%M")}"
            end

        # Add your footer content
        footer = 
        "Autour d'un soir - Cannes
        \n 04 93 00 00 00
        \n https://example.com "

        @message_full += next_meeting
        @message_full += "\n\n#{footer}"
 
        attachments["#{doc_edition.doc_type}_#{doc_edition.commande.ref_commande}.pdf"] = pdf_data
    
        mail(to: doc_edition.destinataire, subject: doc_edition.sujet, body: @message_full) 
    
    end

   

    
end
