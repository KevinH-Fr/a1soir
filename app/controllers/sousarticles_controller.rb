class SousarticlesController < ApplicationController
  before_action :set_sousarticle, only: %i[ show edit update destroy ]

  def index
    @sousarticles = Sousarticle.all
  end

  def show
  end

  def new
    @sousarticle = Sousarticle.new
    @articleId = params[:articleId]
  end

  def edit
    @articleId = params[:articleId]
  end

  def create
    @commandeId = Article.find(@sousarticle.article_id).commande_id
    @produitId = Article.find(@sousarticle.article_id).produit_id

    @sousarticle = Sousarticle.new(sousarticle_params)

    respond_to do |format|
      if @sousarticle.save
        format.html { redirect_to edit_article_path(@sousarticle.article_id, commandeId: @commandeId, produitId:  @produitId), 
             notice: "Sousarticle was successfully created." }
        format.json { render :show, status: :created, location: @sousarticle }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @sousarticle.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @commandeId = Article.find(@sousarticle.article_id).commande_id
    @produitId = Article.find(@sousarticle.article_id).produit_id

    respond_to do |format|
      if @sousarticle.update(sousarticle_params)
        format.html { redirect_to edit_article_path(@sousarticle.article_id, commandeId: @commandeId, produitId:  @produitId), 
             notice: "Sousarticle was successfully updated." }
        format.json { render :show, status: :ok, location: @sousarticle }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @sousarticle.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy

    @commandeId = Article.find(@sousarticle.article_id).commande_id
    @produitId = Article.find(@sousarticle.article_id).produit_id

    @sousarticle.destroy

    respond_to do |format|
      format.html { redirect_to edit_article_path(@sousarticle.article_id, commandeId: @commandeId, produitId:  @produitId), notice: "Sousarticle was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

    def set_sousarticle
      @sousarticle = Sousarticle.find(params[:id])
    end

    def sousarticle_params
      params.require(:sousarticle).permit(:article_id, :nature, :description, :prix_sousarticle, :caution, :taille)
    end
end
