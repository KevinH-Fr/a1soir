class PdfController < ApplicationController
    def generate_commande
        @commande = Commande.find(params[:commande])
        @type_doc = params[:type_doc]

        pdf = WickedPdf.new.pdf_from_string(
            render_to_string(
              template: "pdf_commande/document", 
              formats: [:html],
              disposition: :inline,              
              layout: 'pdf'
            ),
    
            header: {
                content: render_to_string(
                    'shared/doc_entete')
            },

            footer: {
                content: render_to_string(
                  'shared/doc_footer' )
            }
        )
        
        send_data pdf,
        filename: "#{@typedoc}_" "#{@commande.ref_commande}.pdf",
        type: 'application/pdf',
        disposition: 'inline'

    end

    def send_email
        to_email = 'recipient@example.com' # Replace with the recipient's email
        subject = 'Your Email Subject'
        message = 'Your email message'
    
        CommandeMailer.send_email(to_email, subject, message).deliver_now
        redirect_to root_path, notice: 'Email sent successfully!'
      end

end
