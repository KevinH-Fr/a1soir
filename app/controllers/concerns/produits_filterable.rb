module ProduitsFilterable
  extend ActiveSupport::Concern

  # Méthode pour charger toutes les données nécessaires aux filtres
  # Si produits_scope est fourni, calcule les options dynamiquement
  def load_data(produits_scope: nil, categories_scope: nil, tailles_scope: nil, couleurs_scope: nil, types_scope: nil, types_produits_scope: nil, prix_scope: nil)
    if produits_scope.present?
      # Calculer les options disponibles à partir des produits filtrés
      load_dynamic_filter_options(
        produits_scope,
        categories_scope: categories_scope,
        tailles_scope: tailles_scope,
        couleurs_scope: couleurs_scope,
        types_scope: types_scope,
        types_produits_scope: types_produits_scope,
        prix_scope: prix_scope
      )
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

          turbo_stream.update("filtres-actifs",
            partial: "public/pages/filtres/filtres_actifs"),

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
    search_params = params.permit(:format, :page,
      q: [:nom_or_description_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_cont],
      id: []
    )

    produits_scope = filtered_produits_scope
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

    # Calcul des options en facettes:
    # pour chaque filtre, on applique tous les autres filtres sauf lui-même.
    categories_scope = available_scope_for_filter(:categorie, search_params)
    tailles_scope = available_scope_for_filter(:taille, search_params)
    couleurs_scope = available_scope_for_filter(:couleur, search_params)
    types_scope = available_scope_for_filter(:type, search_params)
    types_produits_scope = available_scope_for_filter(:type_produit, search_params)
    prix_scope = available_scope_for_filter(:prix, search_params)

    # 🔁 Charger les options de filtres dynamiquement à partir des produits disponibles
    load_data(
      produits_scope: available_produits_for_filters,
      categories_scope: categories_scope,
      tailles_scope: tailles_scope,
      couleurs_scope: couleurs_scope,
      types_scope: types_scope,
      types_produits_scope: types_produits_scope,
      prix_scope: prix_scope
    )

    # Scope pour la pagination avec ORDER BY (requête simple sans DISTINCT)
    available_produits_scope = Produit.where(id: available_produits_ids)
                                      .reorder("produits.coup_de_coeur DESC, produits.updated_at DESC")

    # 🔁 Then paginate the available produits (5 per page)
    @pagy, @produits = pagy(available_produits_scope, items: 4)
  end

  # Calcule les options de filtres disponibles à partir d'un scope de produits
  # Chaque scope optionnel permet de calculer une facette avec tous les autres filtres actifs,
  # sauf la facette en question.
  def load_dynamic_filter_options(produits_scope, categories_scope: nil, tailles_scope: nil, couleurs_scope: nil, types_scope: nil, types_produits_scope: nil, prix_scope: nil)
    # Catégories disponibles
    scope_pour_categories = categories_scope || produits_scope
    categorie_ids = scope_pour_categories
                      .joins(:categorie_produits)
                      .distinct
                      .pluck('categorie_produits.id')
    @toutes_categories = CategorieProduit
                           .where(id: categorie_ids)
                           .order(nom: :asc)

    # Tailles disponibles
    scope_pour_tailles = tailles_scope || produits_scope
    taille_ids = scope_pour_tailles
                   .where.not(taille_id: nil)
                   .distinct
                   .pluck(:taille_id)
    @toutes_tailles = Taille
                        .where(id: taille_ids)
                        .order(:nom)

    # Couleurs disponibles
    scope_pour_couleurs = couleurs_scope || produits_scope
    couleur_ids = scope_pour_couleurs
                    .where.not(couleur_id: nil)
                    .distinct
                    .pluck(:couleur_id)
    @toutes_couleurs = Couleur
                         .where(id: couleur_ids)
                         .order(:nom)

    # Types produits disponibles
    scope_pour_types_produits = types_produits_scope || produits_scope
    type_produit_ids = scope_pour_types_produits
                         .where.not(type_produit_id: nil)
                         .distinct
                         .pluck(:type_produit_id)
    @types_produits = TypeProduit
                        .where(id: type_produit_ids)
                        .order(nom: :asc)

    # Tranches de prix disponibles selon les autres filtres actifs.
    scope_pour_prix = prix_scope || produits_scope
    @tranches_prix = [50, 100, 200, 500, 1000].select do |max_price|
      scope_pour_prix.by_prixmax(max_price).exists?
    end

    # Types (Vente/Location) - vérifier lesquels existent
    scope_pour_types = types_scope || produits_scope
    has_vente = scope_pour_types.where("prixvente > 0").exists?
    has_location = scope_pour_types.where("prixlocation > 0").exists?
    @types = []
    @types << "Vente" if has_vente
    @types << "Location" if has_location
  end

  def available_scope_for_filter(excluded_filter, search_params)
    filtered_scope = filtered_produits_scope(excluded_filter: excluded_filter)
    search_scope = filtered_scope.ransack(search_params[:q]).result
    available_ids = search_scope.where(today_availability: true)
                                .reorder(nil)
                                .pluck(:id)
                                .uniq

    Produit.where(id: available_ids)
  end

  def filtered_produits_scope(excluded_filter: nil)
    categorie_param = excluded_filter == :categorie ? nil : params[:id]
    taille_param = excluded_filter == :taille ? nil : params[:taille]
    couleur_param = excluded_filter == :couleur ? nil : params[:couleur]
    prix_param = excluded_filter == :prix ? nil : params[:prixmax]
    type_param = excluded_filter == :type ? nil : params[:type]
    type_produit_param = excluded_filter == :type_produit ? nil : params[:type_produit]
    en_promotion_param = excluded_filter == :prix ? nil : params[:en_promotion]

    FiltersProduitsService.new(
      categorie_param,
      taille_param,
      couleur_param,
      prix_param,
      type_param,
      type_produit_param,
      en_promotion_param
    ).call
  end
end

