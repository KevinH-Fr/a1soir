class Admin::DocEditionsController < Admin::ApplicationController

 # before_action :authenticate_vendeur_or_admin!

  include ApplicationHelper

  before_action :set_doc_edition, only: %i[ show edit update ]

  def new
    @doc_edition = DocEdition.new doc_edition_params
    @commande = Commande.find(session[:commande])
  
    @next_meeting = @commande.next_upcoming_meeting&.start_time
  
    next_commande_meeting = @commande.next_upcoming_meeting
    next_client_meeting = @commande.client&.next_upcoming_meeting
    @next_meeting = [next_commande_meeting, next_client_meeting].compact.min_by(&:datedebut)
  
    client_locale = @commande.client.language || :fr 
  
    I18n.with_locale(client_locale) do
      doc_type_label = I18n.t("document_types.#{@doc_edition.doc_type}")
      event_type_label = I18n.t("events.#{@commande.typeevent}")
  
      @sujet = I18n.t('commande_email.subject', doc_type: doc_type_label, ref_commande: @commande.ref_commande)
      @destinataire = @commande.client.mail
  
      part_0 = I18n.t('commande_email.body.greeting', client: @commande.client.full_intitule)
      part_1 = I18n.t('commande_email.body.document_info', doc_type: doc_type_label)
      part_2 = @commande.typeevent? ? I18n.t('commande_email.body.event_info', event_type: event_type_label) : ""
      part_3 = @commande.dateevent? ? I18n.t('commande_email.body.date_info', event_date: format_date_in_french(@commande.dateevent)) : ""
  
      @message = "#{part_0}\n\n#{part_1}#{part_2}#{part_3}."
    end
  end  


  def edit

    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@doc_edition, 
          partial: "admin/doc_editions/form", 
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
                    partial: 'admin/doc_editions/form', 
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
        
        flash.now[:success] =  "Création réussie"

        format.turbo_stream do
          render turbo_stream: [
          #  turbo_stream.update('new_doc_edition',
          #    partial: "doc_editions/form"),
  
     #       turbo_stream.update('doc_editions',
     #         partial: "doc_editions/doc_edition",
     #         locals: { doc_edition: @doc_edition }),

              turbo_stream.update('synthese-doc-editions', 
                partial: "admin/doc_editions/synthese"),
 
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
      format.html { redirect_to admin_commande_path(@doc_edition.commande), notice: "email was successfully sended." }
    end
  end

  private

  def generate_pdf_data
    pdf_html = render_to_string(template: 'admin/pdf_commande/document', layout: 'pdf')
    pdf_options = {
      header: {
        content: render_to_string('admin/shared/doc_entete', layout: 'pdf'),
        spacing: 10
      },
      footer: {
        content: render_to_string('admin/shared/doc_footer', layout: 'pdf'),
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
