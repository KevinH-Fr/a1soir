class FiltersProduitsService

  def initialize(categorie, taille, couleur, prixmax, type)
    @categorie = CategorieProduit.find(categorie) if categorie.present?
    @taille = taille
    @couleur = couleur
    @prixmax = prixmax
    @type = type

  end

  def call
    produits = Produit.eshop_diffusion
    produits = produits.by_categorie(@categorie) if @categorie.present?
    produits = produits.by_taille(@taille) if @taille.present?
    produits = produits.by_couleur(@couleur) if @couleur.present?
    produits = produits.by_prixmax(@prixmax) if @prixmax.present?
    produits = produits.by_type(@type)
  
    produits

  end

end
