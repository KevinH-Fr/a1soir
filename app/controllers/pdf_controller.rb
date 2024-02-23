class PdfController < ApplicationController
  def generate_commande
    @commande = Commande.find(params[:commande])
    @type_doc = params[:type_doc]

    pdf_data = generate_pdf_data

    send_pdf_data(pdf_data, "#{@type_doc}_#{@commande.ref_commande}.pdf")
  end

  def send_email
    @commande = Commande.find(params[:commande])
    @type_doc = params[:type_doc]

    pdf_data = generate_pdf_data
    CommandeMailer.email_commande(@type_doc, @commande, pdf_data).deliver_now

    respond_to do |format|
      flash.now[:success] = "Email was successfully created"

      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.prepend('flash', partial: 'layouts/notice', locals: { flash: flash })
        ]
      end
    end
  end

  private

  def generate_pdf_data
    WickedPdf.new.pdf_from_string(
      render_to_string(
        template: "pdf_commande/document",
        formats: [:html],
        disposition: :inline,
        layout: 'pdf',
        assigns: { commande: @commande, type_doc: @type_doc }
      ),
      header: {
        content: render_to_string('shared/doc_entete')
      },
      footer: {
        content: render_to_string('shared/doc_footer')
      }
    )
  end

  def send_pdf_data(pdf_data, filename)
    send_data pdf_data,
              filename: filename,
              type: 'application/pdf',
              disposition: 'inline'
  end
end
