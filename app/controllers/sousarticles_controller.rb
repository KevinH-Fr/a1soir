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
   
    @sousarticle = Sousarticle.new(sousarticle_params)
    @commandeId = Article.find(@sousarticle.article_id).commande_id
    @produitId = Article.find(@sousarticle.article_id).produit_id

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
      format.html { redirect_to commande_path(@commandeId), notice: "Sousarticle was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def toggle_sousarticleauto

    @articleId = params[:articleId]
    @commandeId = params[:commandeId]
    @produitId = params[:produitId]

    valCategorie = Produit.find(@produitId).categorie

    if valCategorie == "Costumes hommes"
      sousarticle = Sousarticle.create(article_id: @articleId, nature: "chemise")
      sousarticle = Sousarticle.create(article_id: @articleId, nature: "veste")
      sousarticle = Sousarticle.create(article_id: @articleId, nature: "pantalon")
    else
      sousarticle = Sousarticle.create(article_id: @articleId, nature: "retouches")
    end 

      redirect_to edit_article_path(@articleId, 
        produitId: @produitId, commandeId: @commandeId, 
        articleId: @articleId),
        notice: "test sous article auto  #{@articleId}" 
  end

  private

    def set_sousarticle
      @sousarticle = Sousarticle.find(params[:id])
    end

    def sousarticle_params
      params.fetch(:sousarticle, {}).permit(:article_id, :nature, :description, :prix_sousarticle, :caution, :taille)
    end
end
