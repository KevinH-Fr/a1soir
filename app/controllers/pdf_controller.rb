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

            #footer: {
            #    content: render_to_string(
            #      'shared/doc_footer',
            #      layout: 'pdf'
            #    )
            #}
        )
        
        send_data pdf,
        filename: "#{@typedoc}_" "#{@commande.ref_commande}.pdf",
        type: 'application/pdf',
        disposition: 'inline'

    end
end
