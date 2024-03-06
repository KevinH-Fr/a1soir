class EnsemblesController < ApplicationController
  before_action :set_ensemble, only: %i[ show edit update destroy ]

  def index
    @ensembles = Ensemble.all
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
          partial: "ensembles/form", 
          locals: {ensemble: @ensemble})
      end
    end
  end

  def create
    @ensemble = Ensemble.new(ensemble_params)

    respond_to do |format|
      if @ensemble.save

        flash.now[:success] = "ensemble was successfully created"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "ensembles/form",
                                locals: { ensemble: Ensemble.new }),
  
            turbo_stream.prepend('ensembles',
                                  partial: "ensembles/ensemble",
                                  locals: { ensemble: @ensemble }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to ensemble_url(@ensemble), notice: "Ensemble was successfully created." }
        format.json { render :show, status: :created, location: @ensemble }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ensemble.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @ensemble.update(ensemble_params)

        flash.now[:success] = "ensemble was successfully updated"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@ensemble, partial: "ensembles/ensemble", locals: {ensemble: @ensemble}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to ensemble_url(@ensemble), notice: "Ensemble was successfully updated." }
        format.json { render :show, status: :ok, location: @ensemble }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ensemble.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @ensemble.destroy!

    respond_to do |format|
      format.html { redirect_to ensembles_url, notice: "Ensemble was successfully destroyed." }
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