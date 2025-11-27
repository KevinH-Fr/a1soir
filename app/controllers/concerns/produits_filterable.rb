module ProduitsFilterable
  extend ActiveSupport::Concern

  included do
    # Code qui sera exécuté lors de l'inclusion du module
  end

  # Méthode pour charger toutes les données nécessaires aux filtres
  def load_data
    @toutes_categories = CategorieProduit.all.order(nom: :asc)
    @toutes_tailles = Taille.all.sort_by(&:nom)
    @toutes_couleurs = Couleur.all.sort_by(&:nom)
    @tranches_prix = [50, 100, 200, 500, 1000]
    @types = ["Vente", "Location"]
    @types_produits = TypeProduit.all.order(nom: :asc)
  end

  # Logique principale pour afficher les produits filtrés
  def produits_with_filters
    load_filtered_and_paginated_produits
  end

  # Méthode pour mettre à jour les filtres via Turbo Stream
  def update_filters_turbo
    load_filtered_and_paginated_produits

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("filtres-categorie",
            partial: "public/pages/filtres/filtres_categorie"),

          turbo_stream.update("filtres-type-produit",
            partial: "public/pages/filtres/filtres_type_produit"),
              
          turbo_stream.update("filtres-taille", 
            partial: "public/pages/filtres/filtres_taille"),

          turbo_stream.update("filtres-couleur", 
            partial: "public/pages/filtres/filtres_couleur"),

          turbo_stream.update("filtres-prix", 
            partial: "public/pages/filtres/filtres_prix"),

          turbo_stream.update("filtres-type", 
            partial: "public/pages/filtres/filtres_type"),

          turbo_stream.update("produits-filtres", 
            partial: "public/pages/produits_filtres")
        ]
      end
      format.html
    end
  end

  private

  # Méthode privée pour charger les produits filtrés et paginés
  # Utilisée par produits_with_filters et update_filters_turbo
  def load_filtered_and_paginated_produits
    load_data
  
    # Support both single ID and array of IDs for categories
    categorie_param = params[:id].is_a?(Array) ? params[:id] : params[:id]
  
    produits_scope = FiltersProduitsService.new(
      categorie_param, params[:taille], params[:couleur],
      params[:prixmax], params[:type], 
      params[:type_produit]
    ).call
  
    search_params = params.permit(:format, :page,
      q: [:nom_or_description_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_cont],
      id: []
    )
  
    @q = produits_scope.ransack(search_params[:q])
    searched_produits = @q.result(distinct: true).order(nom: :asc)
  
    # ✅ Filtre de disponibilité utilisant le champ today_availability
    # Ce champ est calculé et mis à jour :
    # - Par un job quotidien (UpdateTodayAvailabilityJob) qui recalcule tous les produits
    # - Par des callbacks en temps réel sur Article, Sousarticle, StripePaymentItem, Commande, Produit
    # Cela évite de recalculer la disponibilité à chaque requête (optimisation performance)
    
    # Ancien code avec calcul en temps réel (DÉSACTIVÉ - trop lent)
    # datedebut = Time.current
    # datefin   = Time.current
    # 
    # available_produits_ids = searched_produits.select do |produit|
    #   produit.statut_disponibilite(datedebut, datefin)[:disponibles] > 0
    # end.map(&:id)
    # available_produits_scope = Produit.where(id: available_produits_ids).order(updated_at: :desc)
    
    # Nouveau code utilisant le champ today_availability (optimisé)
    # Filtre directement sur la colonne today_availability qui est indexée
    available_produits_scope = searched_produits.where(today_availability: true).order(updated_at: :desc)

    # 🔁 Then paginate the available produits (3 per page)
    @pagy, @produits = pagy(available_produits_scope, items: 6)
  end
end

