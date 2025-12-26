module ProduitsFilterable
  extend ActiveSupport::Concern

  # Méthode pour charger toutes les données nécessaires aux filtres
  # Si produits_scope est fourni, calcule les options dynamiquement
  def load_data(produits_scope: nil)
    if produits_scope.present?
      # Calculer les options disponibles à partir des produits filtrés
      load_dynamic_filter_options(produits_scope)
    else
      # Charger toutes les options (comportement par défaut)
      @toutes_categories = CategorieProduit.all.order(nom: :asc)
      @toutes_tailles = Taille.all.sort_by(&:nom)
      @toutes_couleurs = Couleur.all.sort_by(&:nom)
      @tranches_prix = [50, 100, 200, 500, 1000]
      @types = ["Vente", "Location"]
      @types_produits = TypeProduit.all.order(nom: :asc)
    end
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
    searched_produits = @q.result
  
    # ✅ Filtre de disponibilité utilisant le champ today_availability
    # Ce champ est calculé et mis à jour :
    # - Par un job quotidien (UpdateTodayAvailabilityJob) qui recalcule tous les produits
    # - Par des callbacks en temps réel sur Article, Sousarticle, StripePaymentItem, Commande, Produit
    # Cela évite de recalculer la disponibilité à chaque requête (optimisation performance)
    
    # Utiliser une sous-requête pour éviter le problème de DISTINCT avec ORDER BY
    # Récupérer les IDs sans ORDER BY pour éviter les conflits
    available_produits_ids = searched_produits.where(today_availability: true)
                                              .reorder(nil)
                                              .pluck(:id)
                                              .uniq
    
    # Scope pour charger les données de filtres (sans ORDER BY pour éviter les conflits avec DISTINCT)
    available_produits_for_filters = Produit.where(id: available_produits_ids)
    
    # 🔁 Charger les options de filtres dynamiquement à partir des produits disponibles
    load_data(produits_scope: available_produits_for_filters)

    # Scope pour la pagination avec ORDER BY (requête simple sans DISTINCT)
    available_produits_scope = Produit.where(id: available_produits_ids)
                                      .reorder("produits.coup_de_coeur DESC, produits.updated_at DESC")

    # 🔁 Then paginate the available produits (5 per page)
    @pagy, @produits = pagy(available_produits_scope, items: 5)
  end

  # Calcule les options de filtres disponibles à partir d'un scope de produits
  def load_dynamic_filter_options(produits_scope)
    # Catégories disponibles
    categorie_ids = produits_scope
                      .joins(:categorie_produits)
                      .distinct
                      .pluck('categorie_produits.id')
    @toutes_categories = CategorieProduit
                           .where(id: categorie_ids)
                           .order(nom: :asc)

    # Tailles disponibles
    taille_ids = produits_scope
                   .where.not(taille_id: nil)
                   .distinct
                   .pluck(:taille_id)
    @toutes_tailles = Taille
                        .where(id: taille_ids)
                        .order(:nom)

    # Couleurs disponibles
    couleur_ids = produits_scope
                    .where.not(couleur_id: nil)
                    .distinct
                    .pluck(:couleur_id)
    @toutes_couleurs = Couleur
                         .where(id: couleur_ids)
                         .order(:nom)

    # Types produits disponibles
    type_produit_ids = produits_scope
                         .where.not(type_produit_id: nil)
                         .distinct
                         .pluck(:type_produit_id)
    @types_produits = TypeProduit
                        .where(id: type_produit_ids)
                        .order(nom: :asc)

    # Tranches de prix (on garde les tranches fixes pour l'instant)
    @tranches_prix = [50, 100, 200, 500, 1000]

    # Types (Vente/Location) - vérifier lesquels existent
    has_vente = produits_scope.where("prixvente > 0").exists?
    has_location = produits_scope.where("prixlocation > 0").exists?
    @types = []
    @types << "Vente" if has_vente
    @types << "Location" if has_location
  end
end

