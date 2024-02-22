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
        @commande = Commande.find(params[:commande])

        @type_doc = params[:type_doc]
        CommandeMailer.email_commande(@type_doc, @commande).deliver_now
        
       # redirect_to commande_path(@commande), notice: 'Email sent successfully!'

        puts " ______________send email done_______________________"


        respond_to do |format|
      
              
              flash.now[:success] = "email was successfully created"
             # flash[:notice] = 'Email sent successfully!'

              format.turbo_stream do
                render turbo_stream: [


                  turbo_stream.prepend('flash', partial: 'layouts/notice', locals: { flash: flash })
      
                ]
              end
        end

            


    end

end
