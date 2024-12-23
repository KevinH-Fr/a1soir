class CommandesController < ApplicationController
  before_action :authenticate_vendeur_or_admin!

  before_action :set_commande, only: [:show, :edit, :update, :destroy, 
    :toggle_statut_non_retire, :toggle_statut_retire, :toggle_statut_rendu]

  def index

    search_params = params.permit(:format, :page, 
      q:[:nom_or_type_locvente_or_typeevent_cont])
   @q = Commande.ransack(search_params[:q])
   commandes = @q.result(distinct: true).order(created_at: :desc)
   @pagy, @commandes = pagy_countless(commandes, items: 2)

    
    @clients = Client.all
    @profiles = Profile.all 

  end

  def show
    @commande = Commande.find(params[:event]) if params[:commande]
    session[:commande] = @commande.id if @commande

    @produits = Produit.all 
    @doc_edition = DocEdition.new

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
          partial: "commandes/form", 
          locals: {commande: @commande})
      end
    end

  end

  def create
    @commande = Commande.new(commande_params)
    @clients = Client.all
    @profiles = Profile.all 

    respond_to do |format|
      if @commande.save

        #flash.now[:success] = "commande was successfully created"

        #format.turbo_stream do
        #  render turbo_stream: [
        #    turbo_stream.update('new',
        #                        partial: "commandes/form",
        #                        locals: { commande: Commande.new }),
  
        #    turbo_stream.prepend('commandes',
        #                          partial: "commandes/commande",
        #                          locals: { commande: @commande }),
        #    turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
        #    
        #  ]
        #end

        format.html { redirect_to commande_url(@commande), notice:  I18n.t('notices.successfully_created') }
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

    respond_to do |format|
      if @commande.update(commande_params)

        flash.now[:success] =  I18n.t('notices.successfully_updated')

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@commande, partial: "commandes/commande", locals: {commande: @commande}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to commande_url(@commande), notice: "Commande was successfully updated." }
        format.json { render :show, status: :ok, location: @commande }
      else

        
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@commande, 
                    partial: 'commandes/form', 
                    locals: { commande: @commande })
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

      format.html { redirect_to root_path, notice:  I18n.t('notices.successfully_destroyed') }
      format.json { head :no_content }
    end
  end


  def toggle_statut_retire
    @commande.update(statutarticles: "retiré" )
    redirect_to commande_path(@commande),
      notice: "commande retirée par client" 
  end

  def toggle_statut_non_retire
    @commande.update(statutarticles: "non-retiré" )
    redirect_to commande_path(@commande),
      notice: "commande non-retirée par client" 
  end

  def toggle_statut_rendu
    @commande.update(statutarticles: "rendu" )
    redirect_to commande_path(@commande),
      notice: "commande rendue par client" 
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_commande
      @commande = Commande.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def commande_params
      params.require(:commande).permit(:nom, :montant, :description, :client_id, :debutloc, :finloc, :dateevent, 
        :statutarticles, :typeevent, :profile_id, :commentaires, :commentaires_doc, :type_locvente, :devis)
    end

    
end
