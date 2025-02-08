class Admin::SousarticlesController < Admin::ApplicationController

 # before_action :authenticate_vendeur_or_admin!

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
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@sousarticle, 
          partial: "admin/sousarticles/form", 
          locals: { commande_id: @sousarticle.article.commande_id, 
                    produit_id: @sousarticle.produit_id, 
                    article: @sousarticle.article,
                    sousarticle: @sousarticle})
      end
    end
  end

  def create
    @sousarticle = Sousarticle.new(sousarticle_params)

    respond_to do |format|
      if @sousarticle.save

        @commande = @sousarticle.article.commande

        format.html { redirect_to admin_commande_url(@commande), notice:  'sous article successfully_created'}
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

        @commande = @sousarticle.article.commande

        flash.now[:success] = "Sousarticle was successfully updated."

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@sousarticle, 
              partial: "admin/sousarticles/sousarticle", 
              locals: {sousarticle: @sousarticle}),

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
    @commande = @sousarticle.article.commande
    @sousarticle.destroy!

    respond_to do |format|

      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@sousarticle),     
          turbo_stream.update('synthese-articles', 
            partial: "admin/articles/synthese", 
            locals: { articles: @commande.articles }),

          turbo_stream.update('synthese-commande', 
            partial: "admin/commandes/synthese") 
  
          ]
      end

      format.html { redirect_to sousarticles_url, notice: "sous article supprimé"  }
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
