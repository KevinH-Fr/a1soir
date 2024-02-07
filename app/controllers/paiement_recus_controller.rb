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
  end

  # POST /paiement_recus or /paiement_recus.json
  def create
    @paiement_recu = PaiementRecu.new(paiement_recu_params)

    respond_to do |format|
      if @paiement_recu.save
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
