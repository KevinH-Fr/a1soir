class CommandesController < ApplicationController
  before_action :set_commande, only: [:show, :edit, :update, :destroy]

  # GET /commandes or /commandes.json
  def index
    @commandes = Commande.all
    @clients = Client.all
    @profiles = Profile.all 

  end

  # GET /commandes/1 or /commandes/1.json
  def show
    @commande = Commande.find(params[:event]) if params[:commande]
    session[:commande] = @commande.id if @commande

    @produits = Produit.all 


  end

  # GET /commandes/new
  def new
    @commande = Commande.new
    @clients = Client.all
    @profiles = Profile.all 

  end

  # GET /commandes/1/edit
  def edit
    @clients = Client.all
    @profiles = Profile.all 

    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@commande, 
          partial: "commandes/form", 
          locals: {commande: @commande})
      end
    end

  end

  # POST /commandes or /commandes.json
  def create
    @commande = Commande.new(commande_params)
    @clients = Client.all
    @profiles = Profile.all 

    respond_to do |format|
      if @commande.save

        flash.now[:success] = "commande was successfully created"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "commandes/form",
                                locals: { commande: Commande.new }),
  
            turbo_stream.prepend('commandes',
                                  partial: "commandes/commande",
                                  locals: { commande: @commande }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to commande_url(@commande), notice: "Commande was successfully created." }
        format.json { render :show, status: :created, location: @commande }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @commande.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /commandes/1 or /commandes/1.json
  def update
    @clients = Client.all

    respond_to do |format|
      if @commande.update(commande_params)

        flash.now[:success] = "commande was successfully updated"

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

  # DELETE /commandes/1 or /commandes/1.json
  def destroy
    @commande.destroy!

    respond_to do |format|
      format.html { redirect_to commandes_url, notice: "Commande was successfully destroyed." }
      format.json { head :no_content }
    end
  end

 # def selection_articles

 #   @produits = Produit.all 
 #   @commande = Commande.find(session[:commande])

 #   respond_to do |format|
 #     format.turbo_stream do
 #       render turbo_stream: 
 #         turbo_stream.append(
 #           'partial-selection', 
 #           partial: 'commandes/selection_articles'
 #         )
 #     end
 #     format.html 
 #   end
 # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_commande
      @commande = Commande.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def commande_params
      params.require(:commande).permit(:nom, :montant, :description, :client_id, :debutloc, :finloc, :dateevent, :statutarticles, :typeevent, :profile_id, :commentaires, :commentaires_doc, :location, :devis)
    end
end
