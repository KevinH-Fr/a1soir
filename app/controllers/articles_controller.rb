class ArticlesController < ApplicationController
  before_action :set_article, only: %i[ show edit update destroy ]

  # GET /articles or /articles.json
  def index
    @articles = Article.all
  end

  # GET /articles/1 or /articles/1.json
  def show
  end

  # GET /articles/new
  def new
    @article = Article.new

  end

  def edit

    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@article, 
          partial: "articles/form", 
          locals: { commande_id: @article.commande_id, produit_id: @article.produit_id, article: @article})
      end
    end

  end
  # POST /articles or /articles.json
  def create
    @article = Article.new(article_params)

    respond_to do |format|
      if @article.save
        
        flash.now[:success] = "article was successfully created"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "articles/form",
                                locals: { commande_id: @article.commande.id, produit_id: @article.produit.id, article: Article.new }),
  
            turbo_stream.append('articles',
                                  partial: "articles/article",
                                  locals: { article: @article }),
            
            turbo_stream.update( 'partial-selection' ),

            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to article_url(@article), notice: "Article was successfully created." }
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

    respond_to do |format|
      if @article.update(article_params)

        flash.now[:success] = "Article was successfully updated"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@article, partial: "articles/article", locals: {article: @article}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash }),
      
            #turbo_stream.update(
            #  'partial-articles', partial: 'articles/articles'
            # )
   
          ]
        end

        format.html { redirect_to article_url(@article), notice: "Article was successfully updated." }
        format.json { render :show, status: :ok, location: @article }
      else
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

      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@article),
          
          turbo_stream.update(
            'partial-articles', partial: 'articles/articles'
           ),

           turbo_stream.remove(
            'partial-selection'
           )
          ]
      end

      format.html { redirect_to articles_url, notice: "Article was successfully destroyed." }
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
      params.require(:article).permit(:quantite, :prix, :total, :produit_id, :commande_id, :locvente, :caution, :totalcaution, :longueduree, :commentaires)
    end
end
