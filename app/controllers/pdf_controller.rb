class PdfController < ApplicationController
    def generate_commande
        pdf = WickedPdf.new.pdf_from_string(
            render_to_string(
              template: "commandes/document", 
              formats: [:html],
              disposition: :inline,              
              layout: 'pdf'
            )
          )
            send_data pdf,
            filename: "doc.pdf",
            type: 'application/pdf',
            disposition: 'inline'
          end
end
