class SimilarProductsService
  def initialize(produit, limit: 10)
    @produit = produit
    @limit = limit
  end

  def call
    return Produit.none if @limit <= 0

    categorie_ids = @produit.categorie_produits.pluck(:id)
    couleur_id = @produit.couleur_id

    results = []
    excluded_ids = []

    # Priorité 1 : Même catégorie ET même couleur
    if categorie_ids.any? && couleur_id.present?
      priority_1 = base_scope
        .by_categories(categorie_ids)
        .by_couleur(couleur_id)
        .limit(@limit)
      results.concat(priority_1)
      excluded_ids.concat(priority_1.pluck(:id))
    end

    # Priorité 2 : Même catégorie
    if categorie_ids.any? && results.size < @limit
      priority_2 = base_scope
        .by_categories(categorie_ids)
        .where.not(id: excluded_ids)
        .limit(@limit - results.size)
      results.concat(priority_2)
      excluded_ids.concat(priority_2.pluck(:id))
    end

    # Priorité 3 : Même couleur
    if couleur_id.present? && results.size < @limit
      priority_3 = base_scope
        .by_couleur(couleur_id)
        .where.not(id: excluded_ids)
        .limit(@limit - results.size)
      results.concat(priority_3)
    end

    return Produit.none if results.empty?

    # Dédupliquer par reffrs : ne garder qu'un seul produit par référence
    unique_results = deduplicate_by_reffrs(results)

    return Produit.none if unique_results.empty?

    # Préserver l'ordre de priorité avec CASE WHEN
    ordered_ids = unique_results.map(&:id)
    order_sql = ordered_ids.map.with_index { |id, idx| "WHEN id = #{id} THEN #{idx}" }.join(' ')
    
    Produit
      .where(id: ordered_ids)
      .order(Arel.sql("CASE #{order_sql} END"))
  end

  private

  def base_scope
    Produit
      .where(actif: true)
      .where(today_availability: true)
      .eshop_diffusion
      .where.not(id: @produit.id)
      .order(updated_at: :desc)
  end

  # Déduplique les produits par reffrs : ne garde qu'un seul produit par référence
  # Si plusieurs produits ont la même reffrs, garde le premier (qui a la priorité la plus élevée)
  def deduplicate_by_reffrs(produits)
    seen_reffrs = {}
    unique_produits = []

    produits.each do |produit|
      reffrs = produit.reffrs.presence || "no_ref_#{produit.id}"
      
      unless seen_reffrs[reffrs]
        seen_reffrs[reffrs] = true
        unique_produits << produit
      end
    end

    unique_produits
  end
end
