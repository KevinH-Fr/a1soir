class Admin::PeriodesNonDisponiblesController < Admin::ApplicationController
  before_action :authenticate_admin!
  before_action :set_periode_non_disponible, only: %i[edit update destroy]
  def new
    @periode_non_disponible = PeriodeNonDisponible.new
  end

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(@periode_non_disponible,
          partial: "admin/periodes_non_disponibles/form",
          locals: { periode_non_disponible: @periode_non_disponible })
      end
    end
  end

  def create
    @periode_non_disponible = PeriodeNonDisponible.new(periode_non_disponible_params)

    respond_to do |format|
      if @periode_non_disponible.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("periodes_table_body",
              partial: "admin/periodes_non_disponibles/periode_non_disponible",
              locals: { periode_non_disponible: @periode_non_disponible }),
              turbo_stream.replace('new_periode_non_disponible',
              partial: "admin/periodes_non_disponibles/form",
              locals: { periode_non_disponible: PeriodeNonDisponible.new }),
      
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: { success: "Période non disponible créée avec succès" } })
          ]
        end
        format.html { redirect_to dashboard_admin_parametre_rdvs_path(anchor: "periodes"), notice: "Période non disponible créée avec succès" }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("new_periode_non_disponible",
            partial: "admin/periodes_non_disponibles/form",
            locals: { periode_non_disponible: @periode_non_disponible }),
            status: :unprocessable_entity
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @periode_non_disponible.update(periode_non_disponible_params)
        flash.now[:success] = "Période non disponible mise à jour avec succès"
        
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(@periode_non_disponible,
              partial: "admin/periodes_non_disponibles/periode_non_disponible",
              locals: { periode_non_disponible: @periode_non_disponible }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end
        
        format.html { redirect_to dashboard_admin_parametre_rdvs_path(anchor: "periodes"), notice: "Période non disponible mise à jour avec succès" }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@periode_non_disponible,
            partial: "admin/periodes_non_disponibles/form",
            locals: { periode_non_disponible: @periode_non_disponible }),
            status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @periode_non_disponible.destroy
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@periode_non_disponible),
          turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: { success: "Période non disponible supprimée avec succès" } })
        ]
      end
      format.html { redirect_to dashboard_admin_parametre_rdvs_path(anchor: "periodes"), notice: "Période non disponible supprimée avec succès" }
    end
  end

  private

  def set_periode_non_disponible
    @periode_non_disponible = PeriodeNonDisponible.find(params[:id])
  end

  def periode_non_disponible_params
    params.require(:periode_non_disponible).permit(:date_debut, :date_fin, :recurrence)
  end
end


