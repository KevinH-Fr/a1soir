module Public
  class PagesController < ApplicationController
    layout 'public' 

    def home
      @categories = CategorieProduit.not_service
      @carousel_images = Texte&.first&.carousel_images
    end

    def categories
      @categories = CategorieProduit.all
    end

    def produits
      load_data
    
      produits_scope = FiltersProduitsService.new(
        params[:id], params[:taille], params[:couleur],
        params[:prixmax], params[:type]
      ).call
    
      search_params = params.permit(:format, :page,
        q: [:nom_or_description_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_cont]
      )
    
      @q = produits_scope.ransack(search_params[:q])
      searched_produits = @q.result(distinct: true).order(nom: :asc)
    
      # 🔁 Paginate first
      @pagy, produits_page = pagy(searched_produits, items: 5)
    
      # ✅ Now apply availability filter only to paginated produits
      datedebut = Time.current
      datefin   = Time.current
    
      produits_ids = produits_page.select do |produit|
        produit.statut_disponibilite(datedebut, datefin)[:disponibles] > 0
      end.map(&:id)
    
      @produits = Produit.where(id: produits_ids).order(nom: :asc)
    end
    

    def update_filters

      load_data

      respond_to do |format|

        format.turbo_stream do
          render turbo_stream: [

            turbo_stream.update("filtres-categorie",
              partial: "public/pages/filtres_categorie"),
              
            turbo_stream.update("filtres-taille", 
              partial: "public/pages/filtres_taille"),

            turbo_stream.update("filtres-couleur", 
              partial: "public/pages/filtres_couleur"),

            turbo_stream.update("filtres-prix", 
              partial: "public/pages/filtres_prix"),

            turbo_stream.update("filtres-type", 
              partial: "public/pages/filtres_type"),
              
            turbo_stream.update("produits-filtres", 
              partial: "public/pages/produits_filtres")
          ]
        end
        format.html

      end

    end

    def produit
      @produit = Produit.find(params[:id])
      @meme_produit_meme_couleur_autres_tailles = Produit
      .where(handle: @produit.handle, couleur_id: @produit.couleur_id)
      .where.not(id: @produit.id)
      .joins(:taille) 
      .order('tailles.nom') 
    
      @meme_produit_meme_taille_autres_couleurs = Produit
      .where(handle: @produit.handle, taille_id: @produit.taille_id)
      .where.not(id: @produit.id)
      .joins(:couleur) 

    end

    def cart
      @total_amount = @cart.sum { |item| item.prixvente } # Sum of all item prices
    end

    def contact
      if Texte.last.present?
        @texteContact = Texte.last.contact
        @texteAdresse = Texte.last.adresse
      end
    end

    def cgv  
    end

    def rdv
    end

    def laboutique
      if Texte.last.present?
        @texteContact = Texte.last.contact
        @texteHoraire = Texte.last.horaire
        @texteBoutique = Texte.last.boutique
        @texteAdresse = Texte.last.adresse
      end
    end

    private

    def load_data

      puts " ______________ call load data ____________________"
      @toutes_categories = CategorieProduit.all.order(nom: :asc)
      @toutes_tailles = Taille.all.sort_by(&:nom)
      @toutes_couleurs = Couleur.all.sort_by(&:nom)
      @tranches_prix = [50, 100, 200, 500, 1000]
      @types = ["Vente", "Location"]
    end

  end
end
