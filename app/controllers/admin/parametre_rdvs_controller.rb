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
        admin_push_domain_toast!(flash.now, :rdv, :parametre_created)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("parametres_content",
              partial: "admin/parametre_rdvs/parametre_rdv",
              locals: { parametre_rdv: @parametre_rdv }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end
        
        format.html do
          admin_push_domain_toast!(flash, :rdv, :parametre_created)
          redirect_to dashboard_admin_parametre_rdvs_path(anchor: "parametres")
        end
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
        admin_push_domain_toast!(flash.now, :rdv, :parametre_updated)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("parametres_content",
              partial: "admin/parametre_rdvs/parametre_rdv",
              locals: { parametre_rdv: @parametre_rdv }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end
        
        format.html do
          admin_push_domain_toast!(flash, :rdv, :parametre_updated)
          redirect_to dashboard_admin_parametre_rdvs_path(anchor: "parametres")
        end
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
      admin_push_domain_toast!(flash.now, :rdv, :parametre_destroyed)
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("parametres_content", ""),
          turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
        ]
      end
      format.html do
        admin_push_domain_toast!(flash, :rdv, :parametre_destroyed)
        redirect_to dashboard_admin_parametre_rdvs_path(anchor: "parametres")
      end
    end
  end

  private

  def set_parametre_rdv
    @parametre_rdv = ParametreRdv.order(created_at: :desc).first_or_create!
  end

  def parametre_rdv_params
    permitted = params.require(:parametre_rdv).permit(
      :nom,
      :minutes_par_personne_supp,
      :nb_rdv_simultanes_lundi,
      :nb_rdv_simultanes_mardi,
      :nb_rdv_simultanes_mercredi,
      :nb_rdv_simultanes_jeudi,
      :nb_rdv_simultanes_vendredi,
      :nb_rdv_simultanes_samedi,
      :nb_rdv_simultanes_dimanche,
      creneaux_lundi: [],
      creneaux_mardi: [],
      creneaux_mercredi: [],
      creneaux_jeudi: [],
      creneaux_vendredi: [],
      creneaux_samedi: [],
      creneaux_dimanche: []
    )

    # Valeurs par défaut pour les champs array : []
    defaults = ParametreRdv::CRENEAUX_COLUMNS.index_with { [] }

    permitted.reverse_merge(defaults)
  end
end


