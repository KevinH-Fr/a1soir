class DocEditionsController < ApplicationController

 # before_action :authenticate_vendeur_or_admin!

  before_action :set_doc_edition, only: %i[ show edit update ]

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

  def update

    respond_to do |format|
      if @doc_edition.update(doc_edition_params)

        flash.now[:success] = "doc_edition was successfully updated"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@doc_edition, partial: "doc_editions/doc_edition", locals: {doc_edition: @doc_edition}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to doc_edition_url(@doc_edition), notice: "doc_edition was successfully updated." }
        format.json { render :show, status: :ok, location: @doc_edition }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@doc_edition, 
                    partial: 'doc_editions/form', 
                    locals: { doc_edition: @doc_edition })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @doc_edition.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    @doc_edition = DocEdition.new(doc_edition_params)

    respond_to do |format|
      if @doc_edition.save

        @commande = @doc_edition.commande
        
        flash.now[:success] =  I18n.t('notices.successfully_created')

        format.turbo_stream do
          render turbo_stream: [
          #  turbo_stream.update('new_doc_edition',
          #    partial: "doc_editions/form"),
  
     #       turbo_stream.update('doc_editions',
     #         partial: "doc_editions/doc_edition",
     #         locals: { doc_edition: @doc_edition }),

              turbo_stream.update('synthese-doc-editions', 
                partial: "doc_editions/synthese"),
 
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })

          ]
        end

        format.html { redirect_to doc_edition_url(@doc_edition), notice: "doc_edition was successfully created." }
        format.json { render :show, status: :created, location: @doc_edition }

      end

    end
  end


  def index
    @doc_editions = DocEdition.all
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
    pdf_html = render_to_string(template: 'pdf_commande/document', layout: 'pdf')
    pdf_options = {
      header: {
        content: render_to_string('shared/doc_entete', layout: 'pdf'),
        spacing: 10
      },
      footer: {
        content: render_to_string('shared/doc_footer', layout: 'pdf'),
        spacing: 10
      }
    }
    
    pdf = WickedPdf.new.pdf_from_string(pdf_html, pdf_options)

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
