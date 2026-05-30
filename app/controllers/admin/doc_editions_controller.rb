class Admin::DocEditionsController < Admin::ApplicationController

 # before_action :authenticate_vendeur_or_admin!

  include ApplicationHelper
  include PdfRenderable

  before_action :set_doc_edition, only: %i[ show edit update ]

  def new
    @doc_edition = DocEdition.new doc_edition_params
    @commande = Commande.find(session[:commande])

    if @commande.eshop? && @doc_edition.doc_type.blank?
      @doc_edition.doc_type = "facture"
    end
  
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

        admin_push_domain_toast!(flash.now, :doc_edition, :updated)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@doc_edition, partial: "doc_editions/doc_edition", locals: {doc_edition: @doc_edition}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :doc_edition, :updated)
          redirect_to doc_edition_url(@doc_edition)
        end
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
        
        admin_push_domain_toast!(flash.now, :doc_edition, :created)

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

        format.html do
          admin_push_domain_toast!(flash, :doc_edition, :created)
          redirect_to doc_edition_url(@doc_edition)
        end
        format.json { render :show, status: :created, location: @doc_edition }

      end

    end
  end


  def index
    @doc_editions = DocEdition.all
  end

  def generate_commande
    load_doc_edition_for_pdf!
    send_pdf_with_header_footer(
      template: "admin/pdf_commande/document",
      layout: "pdf",
      filename: "#{@doc_edition.doc_type}_#{@doc_edition.commande.ref_commande}.pdf"
    )
  end


  def send_email
    load_doc_edition_for_pdf!

    deliver_pdf_with_header_footer_email(template: "admin/pdf_commande/document", layout: "pdf") do |pdf_data|
      CommandeMailer.email_commande(@doc_edition, pdf_data)
    end

    respond_to do |format|
      format.html do
        admin_push_domain_toast!(flash, :doc_edition, :email_sent)
        redirect_to admin_commande_path(@doc_edition.commande)
      end
    end

    @doc_edition.update(mail_sent: true)
  end

  private

  # Précharge commande + associations pour le rendu PDF (évite N+1 articles/produits/images).
  # Utilisé par generate_commande et send_email uniquement.
  def load_doc_edition_for_pdf!
    @doc_edition = DocEdition.includes(
      commande: [
        :client,
        :profile,
        :stripe_payment,
        :paiement_recus,
        :avoir_rembs,
        :meetings,
        { qr_code_attachment: :blob },
        {
          articles: {
            produit: [:couleur, :taille, :image1_attachment],
            sousarticles: { produit: [:couleur, :taille, :image1_attachment] }
          }
        }
      ]
    ).find(params[:doc_edition])
  end

  def set_doc_edition
    @doc_edition = DocEdition.find(params[:id])
  end
  
  def doc_edition_params
    params.fetch(:doc_edition, {}).permit(:commande_id, :doc_type, :edition_type, :commentaires, :sujet, :destinataire, :message, :label_facture_simple)
  end


end
