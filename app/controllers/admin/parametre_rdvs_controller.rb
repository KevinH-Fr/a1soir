class Admin::ParametreRdvsController < Admin::ApplicationController
  before_action :authenticate_admin!
  before_action :set_parametre_rdv, only: %i[edit update destroy]

  def dashboard
    @parametre_rdv = ParametreRdv.order(created_at: :desc).first
    @type_rdvs = TypeRdv.ordered
    @periodes_non_disponibles = PeriodeNonDisponible.order(created_at: :desc)
  end

  def create
    @parametre_rdv = ParametreRdv.new(parametre_rdv_params)

    respond_to do |format|
      if @parametre_rdv.save
        flash.now[:success] = "Paramètres RDV créés avec succès"
        
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("parametres_content",
              partial: "admin/parametre_rdvs/parametre_rdv",
              locals: { parametre_rdv: @parametre_rdv }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end
        
        format.html { redirect_to dashboard_admin_parametre_rdvs_path(anchor: "parametres"), notice: "Paramètres RDV créés avec succès" }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("new",
            partial: "admin/parametre_rdvs/form",
            locals: { parametre_rdv: @parametre_rdv }),
            status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("parametres_content",
          partial: "admin/parametre_rdvs/form",
          locals: { parametre_rdv: @parametre_rdv })
      end
    end
  end

  def update
    respond_to do |format|
      if @parametre_rdv.update(parametre_rdv_params)
        flash.now[:success] = "Paramètres RDV mis à jour avec succès"
        
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("parametres_content",
              partial: "admin/parametre_rdvs/parametre_rdv",
              locals: { parametre_rdv: @parametre_rdv }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end
        
        format.html { redirect_to dashboard_admin_parametre_rdvs_path(anchor: "parametres"), notice: "Paramètres RDV mis à jour avec succès" }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("parametres_content",
            partial: "admin/parametre_rdvs/form",
            locals: { parametre_rdv: @parametre_rdv }),
            status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @parametre_rdv.destroy
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("parametres_content", ""),
          turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: { success: "Paramètres RDV supprimés avec succès" } })
        ]
      end
      format.html { redirect_to dashboard_admin_parametre_rdvs_path(anchor: "parametres"), notice: "Paramètres RDV supprimés avec succès" }
    end
  end

  private

  def set_parametre_rdv
    @parametre_rdv = ParametreRdv.order(created_at: :desc).first_or_create!
  end

  def parametre_rdv_params
    params.require(:parametre_rdv).permit(
      :nom,
      :minutes_par_personne_supp,
      :nb_rdv_simultanes_lundi,
      :nb_rdv_simultanes_mardi,
      :nb_rdv_simultanes_mercredi,
      :nb_rdv_simultanes_jeudi,
      :nb_rdv_simultanes_vendredi,
      :nb_rdv_simultanes_samedi,
      :nb_rdv_simultanes_dimanche,
      :creneaux_horaires
    )
  end
end


