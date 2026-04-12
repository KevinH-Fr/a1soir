class Admin::ArticlesController < Admin::ApplicationController
  
  #before_action :authenticate_vendeur_or_admin!

  before_action :set_article, only: %i[ show edit update destroy ]

  # GET /articles or /articles.json
  def index
    @articles = Article.all
  end

  def show
  end

  def new
    @commande = Commande.find(session[:commande])
    
    @article = Article.new article_params
  end

  def edit
    @commande = @article.commande

    @produit = @article.produit

    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@article, 
          partial: "admin/articles/form", 
          locals: { commande_id: @article.commande_id, produit_id: @article.produit_id, article: @article})
      end
    end
  end

  def create
    @article = Article.new(article_params)

    @produits = Produit.all 

    respond_to do |format|
      if @article.save

        @commande = @article.commande

        format.html do
          admin_push_domain_toast!(flash, :article, :created)
          redirect_to admin_selection_produit_path(commande: @commande.id)
        end
        format.json { render :show, status: :created, location: @article }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articles/1 or /articles/1.json
  def update

    @commande = @article.commande
    @produit = @article.produit

    respond_to do |format|
      if @article.update(article_params)

        admin_push_domain_toast!(flash.now, :article, :updated)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@article, 
              partial: "admin/articles/article", 
              locals: {article: @article}),

            turbo_stream.update('synthese-commande', 
              partial: "admin/commandes/synthese") ,
  
              turbo_stream.update('synthese-articles', 
                partial: "admin/articles/synthese", 
                locals: { articles: @commande.articles }),
              turbo_stream.prepend('flash', 
                partial: 'layouts/flash', 
                locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :article, :updated)
          redirect_to article_url(@article)
        end
        format.json { render :show, status: :ok, location: @article }
      else
        format.turbo_stream do
          render turbo_stream:
            turbo_stream.update(@article,
              partial: "admin/articles/form",
              locals: { commande_id: @article.commande_id, produit_id: @article.produit_id, article: @article })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1 or /articles/1.json
  def destroy

    @commande = @article.commande
    @article.destroy!

    respond_to do |format|
      admin_push_domain_toast!(flash.now, :article, :destroyed)

      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@article),
          turbo_stream.update('synthese-articles',
            partial: "admin/articles/synthese",
            locals: { articles: @commande.articles }),

          turbo_stream.update('synthese-commande',
            partial: "admin/commandes/synthese"),

          turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
        ]
      end

      format.html do
        admin_push_domain_toast!(flash, :article, :destroyed)
        redirect_to articles_url
      end
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = Article.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def article_params
      params.fetch(:article, {}).permit(:quantite, :prix, :total, :produit_id, :commande_id, :locvente, :caution, :totalcaution, :longueduree, :commentaires)
    end

end
