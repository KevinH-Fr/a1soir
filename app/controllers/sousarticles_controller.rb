class SousarticlesController < ApplicationController
  before_action :set_sousarticle, only: %i[ show edit update destroy ]

  # GET /sousarticles or /sousarticles.json
  def index
    @sousarticles = Sousarticle.all
  end

  # GET /sousarticles/1 or /sousarticles/1.json
  def show
  end

  # GET /sousarticles/new
  def new
    @sousarticle = Sousarticle.new
  end

  def edit
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@sousarticle, 
          partial: "sousarticles/form", 
          locals: { commande_id: @sousarticle.article.commande_id, 
                    produit_id: @sousarticle.produit_id, 
                    article: @sousarticle.article,
                    sousarticle: @sousarticle})
      end
    end
  end

  # POST /sousarticles or /sousarticles.json
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

  # PATCH/PUT /sousarticles/1 or /sousarticles/1.json
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

  # DELETE /sousarticles/1 or /sousarticles/1.json
  def destroy
    @sousarticle.destroy!

    respond_to do |format|
      format.html { redirect_to sousarticles_url, notice: "Sousarticle was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sousarticle
      @sousarticle = Sousarticle.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def sousarticle_params
      params.require(:sousarticle).permit(:article_id, :produit_id, :nature, :description, :prix, :caution, :commentaires)
    end
end
