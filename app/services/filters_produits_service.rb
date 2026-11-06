class FiltersProduitsService

  def initialize(categorie, taille, couleur, prixmax, type, type_produit, en_promotion = nil, catalogue: Produit::CATALOGUE_TENUES_MARIAGE_SOIREE, rubrique_ids: nil)
    if categorie.present?
      @categories_ids = categorie.is_a?(Array) ? categorie : [categorie]
      @categories_ids = @categories_ids.compact.map(&:to_i)
    end

    if type_produit.present?
      @type_produit_ids = type_produit.is_a?(Array) ? type_produit : [type_produit]
      @type_produit_ids = @type_produit_ids.compact.map(&:to_i)
    end

    if rubrique_ids.present?
      @rubrique_ids = rubrique_ids.is_a?(Array) ? rubrique_ids : [rubrique_ids]
      @rubrique_ids = @rubrique_ids.compact.map(&:to_i).reject(&:zero?)
    end

    @taille = taille
    @couleur = couleur
    @prixmax = prixmax
    @type = type
    @en_promotion = ActiveModel::Type::Boolean.new.cast(en_promotion)
    @catalogue = Produit::CATALOGUES.include?(catalogue) ? catalogue : Produit::CATALOGUE_TENUES_MARIAGE_SOIREE
  end

  def call
    produits = Produit.actif.includes([:couleur]).eshop_diffusion.where(catalogue: @catalogue)

    produits = produits.by_categories(@categories_ids) if @categories_ids.present?
    produits = produits.by_rubriques(@rubrique_ids) if @catalogue == Produit::CATALOGUE_COSTUME_EPOQUE_DEGUISEMENTS && @rubrique_ids.present?
    produits = produits.where(type_produit_id: @type_produit_ids) if @type_produit_ids.present?

    if @taille.present?
      produits = produits.by_taille(@taille)
    else
      produits_uniques = produits.group_by { |p| [p.handle, p.couleur_id] }
                                 .map { |_, ps| ps.find { |p| p.today_availability } || ps.first }
      produits = Produit.where(id: produits_uniques.map(&:id))
    end

    produits = produits.by_couleur(@couleur) if @couleur.present?
    produits = produits.by_type(@type) if @type.present?
    produits = produits.by_prixmax(@prixmax, @type) if @prixmax.present?
    produits = produits.en_promotion if @en_promotion

    produits
  end

end
