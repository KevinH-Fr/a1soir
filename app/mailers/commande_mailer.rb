class CommandeMailer < ApplicationMailer

    def email_commande(type_doc, commande, pdf_data)

        destinataire = commande.client.mail

        subject = type_doc + " " + commande.ref_commande

        part_1 = "Merci de trouver ci-attaché votre #{type_doc}"
        part_2 = commande.typeevent? ? " pour votre #{commande.typeevent}" : ""
        part_3 = commande.dateevent? ? " prévu(e) le #{commande.dateevenement}" : ""

        message = "#{part_1}#{part_2}#{part_3}"

        # Add your footer content
        footer = 
            "Autour d'un soir - Cannes
            \n 04 93 00 00 00
            \n https://example.com "

        message += "\n\n#{footer}"
 
        attachments["#{type_doc}_#{commande.ref_commande}.pdf"] = pdf_data
    
        mail(to: destinataire, subject: subject, body: message) 
    
    end

   

    
end
