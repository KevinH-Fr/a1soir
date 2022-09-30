class ArticlesController < ApplicationController
  before_action :set_article, only: %i[ show edit update destroy ]

  def index
    @articles = Article.all
  end

  def show
  end

  def new
    @article = Article.new article_params

    @commandeId = params[:commandeId]
    session[:commandeId] = params[:commandeId]

    @produitId = params[:produitId]
    session[:produitId] = params[:produitId]
  end

  def edit
    @commandeId = params[:commandeId]
    @produitId = params[:produitId]
  end

  def create
    @article = Article.new(article_params)

    respond_to do |format|
      if @article.save
        format.html { redirect_to article_url(@article), notice: "Article was successfully created." }
        format.json { render :show, status: :created, location: @article }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @article.update(article_params)
        format.html { redirect_to article_url(@article), notice: "Article was successfully updated." }
        format.json { render :show, status: :ok, location: @article }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @article.destroy

    respond_to do |format|
      format.html { redirect_to articles_url, notice: "Article was successfully destroyed." }
      format.json { head :no_content }
    end
  end


  def toggle_selectProduit
    @commandeId = session[:commandeId]
    @produitId =  session[:produitId]

    redirect_to new_article_path(commandeId: @commandeId, produitId: @produitId),
    notice: "test notif selection produit n°#{@produitId} |"  "commande n°#{@commandeId}"

  end


  private
     def set_article
      @article = Article.find(params[:id])
    end

    def article_params
      params.fetch(:article, {}).permit(:quantite, :commande_id, :produit_id, :prix, :total)
    end
end
