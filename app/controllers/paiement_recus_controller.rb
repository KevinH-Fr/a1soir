class PaiementRecusController < ApplicationController
  before_action :set_paiement_recu, only: %i[ show edit update destroy ]

  # GET /paiement_recus or /paiement_recus.json
  def index
    @paiement_recus = PaiementRecu.all
  end

  # GET /paiement_recus/1 or /paiement_recus/1.json
  def show
  end

  # GET /paiement_recus/new
  def new
    @paiement_recu = PaiementRecu.new
  end

  # GET /paiement_recus/1/edit
  def edit

    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@paiement_recu, 
          partial: "paiement_recus/form", 
          locals: {commande_id: @paiement_recu.commande_id, paiement_recu: @paiement_recu})
      end
    end

  end

  # POST /paiement_recus or /paiement_recus.json
  def create
    @paiement_recu = PaiementRecu.new(paiement_recu_params)

    respond_to do |format|
      if @paiement_recu.save

        flash.now[:success] = "paiement was successfully created"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "paiement_recus/form",
                                locals: { commande_id: @paiement_recu.commande.id, paiement_recu: PaiementRecu.new }),
  
            turbo_stream.append('paiement_recus',
                                  partial: "paiement_recus/paiement_recu",
                                  locals: { paiement_recu: @paiement_recu }),
            
          #  turbo_stream.update( 'partial-selection' ),

            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to paiement_recu_url(@paiement_recu), notice: "Paiement recu was successfully created." }
        format.json { render :show, status: :created, location: @paiement_recu }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @paiement_recu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /paiement_recus/1 or /paiement_recus/1.json
  def update
    respond_to do |format|
      if @paiement_recu.update(paiement_recu_params)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@paiement_recu, partial: "paiement_recus/paiement_recu", locals: {paiement_recu: @paiement_recu}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash }),
    
          ]
        end

        format.html { redirect_to paiement_recu_url(@paiement_recu), notice: "Paiement recu was successfully updated." }
        format.json { render :show, status: :ok, location: @paiement_recu }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @paiement_recu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /paiement_recus/1 or /paiement_recus/1.json
  def destroy
    @paiement_recu.destroy!

    respond_to do |format|

      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@paiement_recu)
        ]
      end 
      
      format.html { redirect_to paiement_recus_url, notice: "Paiement recu was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_paiement_recu
      @paiement_recu = PaiementRecu.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def paiement_recu_params
      params.require(:paiement_recu).permit(:typepaiement, :montant, :commande_id, :moyen, :commentaires)
    end
end
