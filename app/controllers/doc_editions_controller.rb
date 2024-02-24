class DocEditionsController < ApplicationController
  before_action :set_doc_edition, only: %i[ show edit ]

  def new
    @doc_edition = DocEdition.new doc_edition_params
    @commande = Commande.find(session[:commande])


    @sujet = "votre #{@doc_edition.doc_type}"
    @destinataire = @commande.client.mail

    part_1 = "Merci de trouver ci-attaché votre #{@doc_edition.doc_type}"
    part_2 = @commande.typeevent? ? " pour votre #{@commande.typeevent}" : ""
    part_3 = @commande.dateevent? ? " prévu(e) le #{@commande.dateevenement}" : ""

    @message ="#{part_1}#{part_2}#{part_3}"
    
  end


  def edit

    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@doc_edition, 
          partial: "doc_editions/form", 
          locals: {doc_edition: @doc_edition})
      end
    end
  end

  def create
    @doc_edition = DocEdition.new(doc_edition_params)

    respond_to do |format|
      if @doc_edition.save

        @commande = @doc_edition.commande

        format.html { redirect_to doc_edition_url(@doc_edition), notice: "doc_edition was successfully created." }
        format.json { render :show, status: :created, location: @doc_edition }

      end

    end
  end


  def generate_commande
    @doc_edition = DocEdition.find(params[:doc_edition])
    pdf_data = generate_pdf_data

    send_pdf_data(pdf_data, "#{@doc_edition.doc_type}_#{@doc_edition.commande.ref_commande}.pdf")
  end


  def send_email
    @doc_edition = DocEdition.find(params[:doc_edition])
    pdf_data = generate_pdf_data

    CommandeMailer.email_commande(@doc_edition, pdf_data).deliver_now

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
        layout: 'pdf'
        #,
        #assigns: { commande: @commande, type_doc: @type_doc, commentaire_doc: @commentaire_doc }
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

  def set_doc_edition
    @doc_edition = DocEdition.find(params[:id])
  end
  
  def doc_edition_params
    params.fetch(:doc_edition, {}).permit(:commande_id, :doc_type, :edition_type, :commentaires, :sujet, :destinataire, :message)
  end
end
