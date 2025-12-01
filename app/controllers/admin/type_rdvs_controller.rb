class Admin::TypeRdvsController < Admin::ApplicationController
  before_action :authenticate_admin!
  before_action :set_type_rdv, only: %i[edit update destroy]



  def new
    @type_rdv = TypeRdv.new
  end

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(@type_rdv,
          partial: "admin/type_rdvs/form",
          locals: { type_rdv: @type_rdv })
      end
    end
  end

  def create
    @type_rdv = TypeRdv.new(type_rdv_params)

    respond_to do |format|
      if @type_rdv.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("types_table_body",
              partial: "admin/type_rdvs/type_rdv",
              locals: { type_rdv: @type_rdv }),

            turbo_stream.update('new_type_rdv',
              partial: "admin/type_rdvs/form",
              locals: { type_rdv: TypeRdv.new }),
      
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: { success: "Type de RDV créé avec succès" } })
          ]
        end
        format.html { redirect_to dashboard_admin_parametre_rdvs_path(anchor: "types"), notice: "Type de RDV créé avec succès" }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("new",
            partial: "admin/type_rdvs/form",
            locals: { type_rdv: @type_rdv }),
            status: :unprocessable_entity
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @type_rdv.update(type_rdv_params)
        flash.now[:success] = "Type de RDV mis à jour avec succès"
        
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(@type_rdv,
              partial: "admin/type_rdvs/type_rdv",
              locals: { type_rdv: @type_rdv }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end
        
        format.html { redirect_to dashboard_admin_parametre_rdvs_path(anchor: "types"), notice: "Type de RDV mis à jour avec succès" }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@type_rdv,
            partial: "admin/type_rdvs/form",
            locals: { type_rdv: @type_rdv }),
            status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @type_rdv.destroy
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@type_rdv),
          turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: { success: "Type de RDV supprimé avec succès" } })
        ]
      end
      format.html { redirect_to dashboard_admin_parametre_rdvs_path(anchor: "types"), notice: "Type de RDV supprimé avec succès" }
    end
  end

  private

  def set_type_rdv
    @type_rdv = TypeRdv.find(params[:id])
  end

  def type_rdv_params
    params.require(:type_rdv).permit(:code, :duree_base_minutes)
  end
end


