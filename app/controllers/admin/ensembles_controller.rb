class Admin::EnsemblesController < Admin::ApplicationController
  before_action :authenticate_admin!

  before_action :set_ensemble, only: %i[ show edit update destroy ]

  def index
    @count_ensembles = Ensemble.count

    search_params = params.permit(:format, :page, 
      q:[:produit_nom_cont])
    @q = Ensemble.ransack(search_params[:q])
    ensembles = @q.result(distinct: true).order(created_at: :desc)
    @pagy, @ensembles = pagy_countless(ensembles, items: 2)

  end

  def show
  end

  def new
    @ensemble = Ensemble.new
  end

  def edit
    respond_to do |format|
      format.html 
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(@ensemble,
          partial: "admin/ensembles/form",
          locals: { ensemble: @ensemble, admin_form_row_embedded: true })
      end
    end
  end

  def create
    @ensemble = Ensemble.new(ensemble_params)

    respond_to do |format|
      if @ensemble.save

        admin_push_domain_toast!(flash.now, :ensemble, :created)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "admin/ensembles/form",
                                locals: { ensemble: Ensemble.new, index_collapse: true }),
  
            turbo_stream.prepend('ensembles',
                                  partial: "admin/ensembles/ensemble",
                                  locals: { ensemble: @ensemble }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :ensemble, :created)
          redirect_to ensemble_url(@ensemble)
        end
        format.json { render :show, status: :created, location: @ensemble }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("new",
            partial: "admin/ensembles/form",
            locals: { ensemble: @ensemble, index_collapse: true })
        end

        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ensemble.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @ensemble.update(ensemble_params)

        admin_push_domain_toast!(flash.now, :ensemble, :updated)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@ensemble, partial: "admin/ensembles/ensemble", locals: {ensemble: @ensemble}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :ensemble, :updated)
          redirect_to ensemble_url(@ensemble)
        end
        format.json { render :show, status: :ok, location: @ensemble }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@ensemble,
            partial: "admin/ensembles/form",
            locals: { ensemble: @ensemble, admin_form_row_embedded: true })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ensemble.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @ensemble.destroy!

    respond_to do |format|
      format.html do
        admin_push_domain_toast!(flash, :ensemble, :destroyed)
        redirect_to admin_ensembles_url
      end
      format.json { head :no_content }
    end
  end

  private
    def set_ensemble
      @ensemble = Ensemble.find(params[:id])
    end
    
    def ensemble_params
      params.require(:ensemble).permit(:produit_id, :type_produit1_id, :type_produit2_id, :type_produit3_id,
        :type_produit4_id, :type_produit5_id, :type_produit6_id)
    end

end
