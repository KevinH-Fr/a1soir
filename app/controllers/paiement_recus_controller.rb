class PaiementRecusController < ApplicationController
  before_action :set_paiement_recu, only: %i[ show edit update destroy ]

  def index
    @paiement_recus = PaiementRecu.all
  end

  def show
  end

  def new
    @paiement_recu = PaiementRecu.new
  end

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

  def create
    @paiement_recu = PaiementRecu.new(paiement_recu_params)
    
    respond_to do |format|
      if @paiement_recu.save
        
        @commande = @paiement_recu.commande

        flash.now[:success] = "paiement was successfully created"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new_paiement',
                                partial: "paiement_recus/form",
                                locals: { commande_id: @paiement_recu.commande.id, paiement_recu: PaiementRecu.new }),
  
            turbo_stream.append('paiement_recus',
                                  partial: "paiement_recus/paiement_recu",
                                  locals: { paiement_recu: @paiement_recu }),
            
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash }),
            turbo_stream.update('synthese-paiements', partial: "paiement_recus/synthese", locals: { articles: @commande.paiement_recus })            
          ]
        end

        format.html { redirect_to paiement_recu_url(@paiement_recu), notice: "Paiement recu was successfully created." }
        format.json { render :show, status: :created, location: @paiement_recu }
      else

        format.turbo_stream do
          render turbo_stream: 
            turbo_stream.update('new_paiement',
                                partial: "paiement_recus/form",
                                locals: {commande_id: @paiement_recu.commande.id, paiement_recu: @paiement_recu })
        end
        
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @paiement_recu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /paiement_recus/1 or /paiement_recus/1.json
  def update

    @commande = @paiement_recu.commande 

    respond_to do |format|
      if @paiement_recu.update(paiement_recu_params)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@paiement_recu, partial: "paiement_recus/paiement_recu", locals: {paiement_recu: @paiement_recu}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash }),
            turbo_stream.update('synthese-paiements', partial: "paiement_recus/synthese", locals: { paiement_recus: @commande.paiement_recus })

          ]
        end

        format.html { redirect_to paiement_recu_url(@paiement_recu), notice: "Paiement recu was successfully updated." }
        format.json { render :show, status: :ok, location: @paiement_recu }
      else

        format.turbo_stream do
          render turbo_stream: 
            turbo_stream.update(@paiement_recu,
                                partial: "paiement_recus/form",
                                locals: {commande_id: @paiement_recu.commande.id, paiement_recu: @paiement_recu })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @paiement_recu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /paiement_recus/1 or /paiement_recus/1.json
  def destroy
    @commande = @paiement_recu.commande
    @paiement_recu.destroy!

    respond_to do |format|

      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@paiement_recu),
          turbo_stream.update('synthese-paiements', partial: "paiement_recus/synthese", locals: { paiement_recus: @commande.paiement_recus })

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
