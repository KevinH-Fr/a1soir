class AvoirRembsController < ApplicationController

  before_action :authenticate_vendeur_or_admin!

  before_action :set_avoir_remb, only: %i[ show edit update destroy ]

  # GET /avoir_rembs or /avoir_rembs.json
  def index
    @avoir_rembs = AvoirRemb.all
  end

  # GET /avoir_rembs/1 or /avoir_rembs/1.json
  def show
  end

  # GET /avoir_rembs/new
  def new
    @avoir_remb = AvoirRemb.new
  end

  # GET /avoir_rembs/1/edit
  def edit
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@avoir_remb, 
          partial: "avoir_rembs/form", 
          locals: {commande_id: @avoir_remb.commande_id, avoir_remb: @avoir_remb})
      end
    end
  end

  # POST /avoir_rembs or /avoir_rembs.json
  def create
    @avoir_remb = AvoirRemb.new(avoir_remb_params)

    respond_to do |format|
      if @avoir_remb.save

        @commande = @avoir_remb.commande

        flash.now[:success] =  "Création réussie"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
              partial: "avoir_rembs/form",
              locals: { commande_id: @avoir_remb.commande.id, avoir_remb: AvoirRemb.new }),
  
            turbo_stream.append('avoir_rembs',
              partial: "avoir_rembs/avoir_remb",
              locals: { avoir_remb: @avoir_remb }),

            turbo_stream.update('synthese-avoirrembs', 
                partial: "avoir_rembs/synthese", 
                locals: { avoir_rembs: @commande.avoir_rembs }),

            turbo_stream.update('synthese-commande', 
              partial: "commandes/synthese"),
                        
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to avoir_remb_url(@avoir_remb), notice: "Avoir remb was successfully created." }
        format.json { render :show, status: :created, location: @avoir_remb }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @avoir_remb.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /avoir_rembs/1 or /avoir_rembs/1.json
  def update

    @commande = @avoir_remb.commande

    respond_to do |format|
      if @avoir_remb.update(avoir_remb_params)

        flash.now[:success] =  "Mise à jour réussie"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@avoir_remb, 
              partial: "avoir_rembs/avoir_remb", 
              locals: {avoir_remb: @avoir_remb}),

            turbo_stream.update('synthese-commande', 
              partial: "commandes/synthese"),

            turbo_stream.update('synthese-avoirrembs', 
              partial: "avoir_rembs/synthese", 
              locals: { avoir_rembs: @commande.avoir_rembs }),
  
            turbo_stream.prepend('flash', 
              partial: 'layouts/flash', 
              locals: { flash: flash })
    
          ]
        end

        format.html { redirect_to avoir_remb_url(@avoir_remb), notice: "Avoir remb was successfully updated." }
        format.json { render :show, status: :ok, location: @avoir_remb }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @avoir_remb.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /avoir_rembs/1 or /avoir_rembs/1.json
  def destroy
    @commande = @avoir_remb.commande
    @avoir_remb.destroy!

    respond_to do |format|

      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@avoir_remb),

          turbo_stream.update('synthese-avoirrembs', 
            partial: "avoir_rembs/synthese", 
            locals: { avoir_rembs: @commande.avoir_rembs }),

          turbo_stream.update('synthese-commande', 
            partial: "commandes/synthese") 

        ]
      end 

      format.html { redirect_to avoir_rembs_url, notice:  "Suppression réussie"  }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_avoir_remb
      @avoir_remb = AvoirRemb.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def avoir_remb_params
      params.require(:avoir_remb).permit(:type_avoir_remb, :montant, :nature, :commande_id, :custom_date)
    end

end
