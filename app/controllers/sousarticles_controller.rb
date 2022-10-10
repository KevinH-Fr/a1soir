class SousarticlesController < ApplicationController
  before_action :set_sousarticle, only: %i[ show edit update destroy ]

  def index
    @sousarticles = Sousarticle.all
  end

  def show
  end

  def new
    @sousarticle = Sousarticle.new
  end

  def edit
  end

  def create
    @sousarticle = Sousarticle.new(sousarticle_params)

    respond_to do |format|
      if @sousarticle.save
        format.html { redirect_to sousarticle_url(@sousarticle), notice: "Sousarticle was successfully created." }
        format.json { render :show, status: :created, location: @sousarticle }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @sousarticle.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @sousarticle.update(sousarticle_params)
        format.html { redirect_to sousarticle_url(@sousarticle), notice: "Sousarticle was successfully updated." }
        format.json { render :show, status: :ok, location: @sousarticle }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @sousarticle.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @sousarticle.destroy

    respond_to do |format|
      format.html { redirect_to sousarticles_url, notice: "Sousarticle was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

    def set_sousarticle
      @sousarticle = Sousarticle.find(params[:id])
    end

    def sousarticle_params
      params.require(:sousarticle).permit(:article_id, :nature, :description, :prix, :caution, :taille)
    end
end
