class FiltersProduitsService

  def initialize(categorie, taille, couleur, prixmax, type, type_produit)
    # Support both single category ID and array of IDs
    if categorie.present?
      @categories_ids = categorie.is_a?(Array) ? categorie : [categorie]
      @categories_ids = @categories_ids.compact.map(&:to_i)
    end
    
    # Support both single type_produit ID and array of IDs
    if type_produit.present?
      @type_produit_ids = type_produit.is_a?(Array) ? type_produit : [type_produit]
      @type_produit_ids = @type_produit_ids.compact.map(&:to_i)
    end
    
    @taille = taille
    @couleur = couleur
    @prixmax = prixmax
    @type = type

  end


  def call
    produits = Produit.all.includes([:couleur]).eshop_diffusion

    produits = produits.by_categories(@categories_ids) if @categories_ids.present?
    
    produits = produits.where(type_produit_id: @type_produit_ids) if @type_produit_ids.present?

    if @taille.present?
      produits = produits.by_taille(@taille)
    else
      produits_uniques = produits.group_by { |p| [p.handle, p.couleur] }.map { |_, ps| ps.first }
      produits = Produit.where(id: produits_uniques.map(&:id))
    end

    produits = produits.by_couleur(@couleur) if @couleur.present?
    produits = produits.by_prixmax(@prixmax) if @prixmax.present?
    produits = produits.by_type(@type) if @type.present?

    produits
  end

end
