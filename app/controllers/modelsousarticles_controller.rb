class ModelsousarticlesController < ApplicationController
  before_action :set_modelsousarticle, only: %i[ show edit update destroy ]

  # GET /modelsousarticles or /modelsousarticles.json
  def index
    @modelsousarticles = Modelsousarticle.all
  end

  # GET /modelsousarticles/1 or /modelsousarticles/1.json
  def show
  end

  # GET /modelsousarticles/new
  def new
    @modelsousarticle = Modelsousarticle.new
  end

  # GET /modelsousarticles/1/edit
  def edit
  end

  # POST /modelsousarticles or /modelsousarticles.json
  def create
    @modelsousarticle = Modelsousarticle.new(modelsousarticle_params)

    respond_to do |format|
      if @modelsousarticle.save
        format.html { redirect_to modelsousarticle_url(@modelsousarticle), notice: "Modelsousarticle was successfully created." }
        format.json { render :show, status: :created, location: @modelsousarticle }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @modelsousarticle.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /modelsousarticles/1 or /modelsousarticles/1.json
  def update
    respond_to do |format|
      if @modelsousarticle.update(modelsousarticle_params)
        format.html { redirect_to modelsousarticle_url(@modelsousarticle), notice: "Modelsousarticle was successfully updated." }
        format.json { render :show, status: :ok, location: @modelsousarticle }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @modelsousarticle.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /modelsousarticles/1 or /modelsousarticles/1.json
  def destroy
    @modelsousarticle.destroy

    respond_to do |format|
      format.html { redirect_to modelsousarticles_url, notice: "Modelsousarticle was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_modelsousarticle
      @modelsousarticle = Modelsousarticle.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def modelsousarticle_params
      params.require(:modelsousarticle).permit(:nature, :description, :prix, :caution)
    end
end
