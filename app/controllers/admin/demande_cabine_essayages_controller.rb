class Admin::DemandeCabineEssayagesController < Admin::ApplicationController

  before_action :set_demande_cabine_essayage, only: %i[ show edit update destroy ]

  def index
    @count_demandes = DemandeCabineEssayage.count

    search_params = params.permit(:format, :page, 
      q:[:nom_or_prenom_or_mail_or_telephone_cont])
    @q = DemandeCabineEssayage.ransack(search_params[:q])
    demandes = @q.result(distinct: true).order(created_at: :desc)
    @pagy, @demande_cabine_essayages = pagy_countless(demandes, items: 2)
  end

  def show
  end

  def new
    @demande_cabine_essayage = DemandeCabineEssayage.new
  end

  def edit
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@demande_cabine_essayage, 
          partial: "admin/demande_cabine_essayages/form", 
          locals: {demande_cabine_essayage: @demande_cabine_essayage})
      end
    end
  end

  def create
    @demande_cabine_essayage = DemandeCabineEssayage.new(demande_cabine_essayage_params)

    respond_to do |format|
      if @demande_cabine_essayage.save
        format.html do
          admin_push_domain_toast!(flash, :demande_cabine, :created)
          redirect_to admin_demande_cabine_essayage_url(@demande_cabine_essayage)
        end
        format.json { render :show, status: :created, location: @demande_cabine_essayage }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @demande_cabine_essayage.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @demande_cabine_essayage.update(demande_cabine_essayage_params)
        admin_push_domain_toast!(flash.now, :demande_cabine, :updated)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@demande_cabine_essayage, 
              partial: "admin/demande_cabine_essayages/demande_cabine_essayage", 
              locals: {demande_cabine_essayage: @demande_cabine_essayage}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :demande_cabine, :updated)
          redirect_to admin_demande_cabine_essayage_url(@demande_cabine_essayage)
        end
        format.json { render :show, status: :ok, location: @demande_cabine_essayage }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @demande_cabine_essayage.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @demande_cabine_essayage.destroy!

    respond_to do |format|
      format.html do
        admin_push_domain_toast!(flash, :demande_cabine, :destroyed)
        redirect_to admin_demande_cabine_essayages_url
      end
      format.json { head :no_content }
    end
  end


  private
    def set_demande_cabine_essayage
      @demande_cabine_essayage = DemandeCabineEssayage.find(params[:id])
    end

    def demande_cabine_essayage_params
      params.require(:demande_cabine_essayage).permit(
        :demande_rdv_id,
        demande_cabine_essayage_items_attributes: [:id, :produit_id, :_destroy]
      )
    end

end

