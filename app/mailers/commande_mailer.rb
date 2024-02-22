class CommandeMailer < ApplicationMailer

    def email_commande(type_doc, commande)

        destinataire = commande.client.mail

        subject = type_doc + " " + commande.ref_commande

        part_1 = "Merci de trouver votre #{type_doc}"
        part_2 = commande.typeevent? ? " pour votre #{commande.typeevent}" : ""
        part_3 = commande.dateevent? ? " prévu(e) le #{commande.dateevenement}" : ""

        message = part_1 + part_2 + part_3

        mail(to: destinataire, subject: subject, body: message)
    end

    
end
