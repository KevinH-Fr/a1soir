class Admin::FournisseursController < Admin::ApplicationController

 # before_action :authenticate_vendeur_or_admin!
  before_action :set_fournisseur, only: %i[ show edit update destroy ]

  def index

   search_params = params.permit(:format, :page, 
      q:[:nom_or_tel_or_mail_cont])
   @q = Fournisseur.ransack(search_params[:q])
   fournisseurs = @q.result(distinct: true).order(created_at: :desc)
   @pagy, @fournisseurs = pagy_countless(fournisseurs, items: 2)

  end

  def show
    @produits = @fournisseur.produits

    datedebut = DateTime.parse(params[:debut]) if params[:debut].present?
    datefin = DateTime.parse(params[:fin]) if params[:fin].present?
    
    @datedebut = DateTime.parse(params[:debut]) if params[:debut].present?
    @datefin = DateTime.parse(params[:fin]) if params[:fin].present?


    if datedebut.present? && datefin.present? 
      @produitsFiltres = @produits.filtredatedebut(datedebut).filtredatefin(datefin)
    else
      @produitsFiltres = @produits
    end

    # Calculate the total sum of (quantite * prixachat) using Ruby iteration
    @total_prixachat_sum = @produitsFiltres.inject(0) do |sum, produit|
      quantite = produit.quantite || 0
      prixachat = produit.prixachat.to_i || 0
      sum + (quantite * prixachat)
    end
    
    @vente_produits = Article.where(produit_id: @produitsFiltres.ids)
    .vente_only

    @location_produits = Article.where(produit_id: @produitsFiltres.ids)
    .location_only

  end

  def new
    @fournisseur = Fournisseur.new
  end

  def edit

    respond_to do |format|
      format.html  
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@fournisseur, 
          partial: "admin/fournisseurs/form", 
          locals: {fournisseur: @fournisseur})
      end
    end
  end

  def create
    @fournisseur = Fournisseur.new(fournisseur_params)

    respond_to do |format|
      if @fournisseur.save

        flash.now[:success] =  "Création réussie"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "admin/fournisseurs/form",
                                locals: { fournisseur: Fournisseur.new }),
  
            turbo_stream.prepend('fournisseurs',
                                  partial: "admin/fournisseurs/fournisseur",
                                  locals: { fournisseur: @fournisseur }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to fournisseur_url(@fournisseur), notice: "Fournisseur was successfully created." }
        format.json { render :show, status: :created, location: @fournisseur }
      else


        format.turbo_stream { render turbo_stream: turbo_stream.replace(
          'fournisseur_form', 
          partial: 'admin/fournisseurs/form', 
          locals: { fournisseur: @fournisseur }
        ) }

        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @fournisseur.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @fournisseur.update(fournisseur_params)

        flash.now[:success] = "Mise à jour réussie"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@fournisseur, partial: "admin/fournisseurs/fournisseur", locals: {fournisseur: @fournisseur}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to fournisseur_url(@fournisseur), notice: "Fournisseur was successfully updated." }
        format.json { render :show, status: :ok, location: @fournisseur }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@fournisseur, 
                    partial: 'admin/fournisseurs/form', 
                    locals: { fournisseur: @fournisseur })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @fournisseur.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @fournisseur.destroy!

    respond_to do |format|
      format.html { redirect_to fournisseurs_url, notice:  "Suppression réussie"  }
      format.json { head :no_content }
    end
  end

  private
    def set_fournisseur
      @fournisseur = Fournisseur.find(params[:id])
    end

    def fournisseur_params
      params.require(:fournisseur).permit(:nom, :tel, :mail, :contact, :site, :notes)
    end

end
