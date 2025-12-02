class Admin::DemandeRdvsController < Admin::ApplicationController

  before_action :set_demande_rdv, only: %i[ edit update destroy ]

  def index
    @count_demandes = DemandeRdv.count

    search_params = params.permit(:format, :page, 
      q:[:nom_or_email_or_telephone_cont])
    @q = DemandeRdv.ransack(search_params[:q])
    demandes = @q.result(distinct: true).order(created_at: :desc)
    @pagy, @demande_rdvs = pagy_countless(demandes, items: 2)
  end


  def edit
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@demande_rdv, 
          partial: "admin/demande_rdvs/form", 
          locals: {demande_rdv: @demande_rdv})
      end
    end
  end

  def update
    respond_to do |format|
      if @demande_rdv.update(demande_rdv_params)
        flash.now[:success] = "Mise à jour réussie"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@demande_rdv, 
              partial: "admin/demande_rdvs/demande_rdv", 
              locals: {demande_rdv: @demande_rdv}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to admin_demande_rdv_url(@demande_rdv), notice: "Mise à jour réussie" }
        format.json { render :show, status: :ok, location: @demande_rdv }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @demande_rdv.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @demande_rdv.destroy!

    respond_to do |format|
      format.html { redirect_to admin_demande_rdvs_path, notice: "Suppression réussie" }
      format.json { head :no_content }
    end
  end

  private
    def set_demande_rdv
      @demande_rdv = DemandeRdv.find(params[:id])
    end

    def demande_rdv_params
      params.require(:demande_rdv).permit(
        :prenom, :nom, :email, :telephone, :commentaire, :date_rdv, :statut, :type_rdv, :nombre_personnes, :evenement, :date_evenement
      )
    end

end

