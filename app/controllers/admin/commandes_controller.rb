class Admin::CommandesController < Admin::ApplicationController
  #before_action :authenticate_vendeur_or_admin!

  before_action :set_commande, only: [:show, :edit, :update, :destroy,
    :toggle_statut_non_retire, :toggle_statut_retire,
    :toggle_statut_rendu_with_email, :toggle_statut_rendu_without_email,
    :marquer_expedie_with_email, :marquer_expedie_without_email]

    def index
      @count_commandes = Commande.count
    
      search_params = params.permit(:format, :page,
        q: [:nom_or_type_locvente_or_typeevent_or_ref_commande_or_client_nom_or_client_prenom_or_profile_nom_or_profile_prenom_cont]
      )

      @q = Commande.joins(:client, :profile).ransack(search_params[:q])
    
      commandes = @q.result(distinct: true)
                    .select("commandes.*")
                    .order("commandes.created_at DESC")
    
    #  Rails.logger.debug commandes.to_sql  # <-- à retirer ensuite
    
      @pagy, @commandes = pagy_countless(commandes, items: 2)
    
      @clients = Client.all
      @profiles = Profile.all
    end
    

  def show

    @commande = Commande.includes(:stripe_payment, articles: [:produit, :sousarticles]).find(params[:commande]) if params[:commande]
    session[:commande] = @commande.id if @commande

    @articles = @commande.articles.includes(produit: [:image1_attachment, :couleur, :taille])

    @produits = Produit.all 
    @doc_edition = DocEdition.new

    @mails_envoyes = @commande.doc_editions.where(mail_sent: true)

  end

  def new
    @commande = Commande.new
    @clients = Client.all
    @profiles = Profile.all 

  end

  def edit
    @clients = Client.all
    @profiles = Profile.all 

    @client = @commande.client
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@commande, 
          partial: "admin/commandes/form", 
          locals: { commande: @commande, admin_form_row_embedded: true })
      end
    end

  end

  def create
    @commande = Commande.new(commande_params)
    @clients = Client.all
    @profiles = Profile.all 

    respond_to do |format|
      if @commande.save
        format.html { redirect_to admin_commande_url(@commande), notice:  "Création réussie" }
        format.json { render :show, status: :created, location: @commande }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @commande.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @clients = Client.all
    @profiles = Profile.all
    @client = @commande.client

    respond_to do |format|
      if @commande.update(commande_params)

        flash.now[:success] =  "Mise à jour réussie"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@commande, partial: "admin/commandes/commande", locals: {commande: @commande}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to commande_url(@commande), notice: "Commande was successfully updated." }
        format.json { render :show, status: :ok, location: @commande }
      else

        
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@commande, 
                    partial: 'admin/commandes/form', 
                    locals: { commande: @commande, admin_form_row_embedded: true })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @commande.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    #@commande.qr_code.purge if @commande.qr_code.attached?
    @commande.destroy!

    
    respond_to do |format|
              
      # format.turbo_stream do
      #   render turbo_stream: turbo_stream.remove(@commande)
      # end

      format.html { redirect_to admin_root_url, notice:  "Suppression réussie" }
      format.json { head :no_content }
    end
  end


  def toggle_statut_retire
    @commande.update(statutarticles: "retiré" )
    redirect_to admin_commande_url(@commande),
      notice: "commande retirée par client" 
  end

  def toggle_statut_non_retire
    @commande.update(statutarticles: "non-retiré" )
    redirect_to admin_commande_url(@commande),
      notice: "commande non-retirée par client" 
  end

  def toggle_statut_rendu_with_email
    @commande.update(statutarticles: "rendu")
    CommandeMailer.confirmation_restitution(@commande).deliver_later
    redirect_to admin_commande_url(@commande),
      notice: "Commande rendue - Email de confirmation envoyé au client"
  end

  def toggle_statut_rendu_without_email
    @commande.update(statutarticles: "rendu")
    redirect_to admin_commande_url(@commande),
      notice: "Commande rendue (sans envoi d'email)"
  end

  def marquer_expedie_with_email
    @commande.update!(numero_suivi: params[:numero_suivi].presence, expedie_le: Time.current)
    StripePaymentMailer.expedition(@commande).deliver_later
    redirect_to admin_commande_url(@commande),
      notice: "Commande expédiée — email envoyé au client"
  end

  def marquer_expedie_without_email
    @commande.update!(numero_suivi: params[:numero_suivi].presence, expedie_le: Time.current)
    redirect_to admin_commande_url(@commande),
      notice: "Commande expédiée (sans email)"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_commande
      @commande = Commande.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def commande_params
      params.require(:commande).permit(:nom, :montant, :description, :client_id, :debutloc, :finloc, :dateevent, 
        :statutarticles, :typeevent, :profile_id, :commentaires, :commentaires_doc, :type_locvente, :devis,
        :numero_suivi, :expedie_le)
    end

    
end
