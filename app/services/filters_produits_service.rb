class FiltersProduitsService

  def initialize(categorie, taille, couleur, prixmax, type)
    @categorie = CategorieProduit.find(categorie) if categorie.present?
    @taille = taille
    @couleur = couleur
    @prixmax = prixmax
    @type = type

  end

  def call
    produits = Produit.all.includes([:couleur]).eshop_diffusion
  
    produits = produits.by_categorie(@categorie) if @categorie.present?

    
    if @taille.present?
      produits = produits.by_taille(@taille)
    else
      produits_uniques = produits.group_by { |p| [p.handle, p.couleur] }.map { |_, ps| ps.first }
      produits = Produit.where(id: produits_uniques.map(&:id))
    end
    
    produits = produits.by_couleur(@couleur) if @couleur.present?
    produits = produits.by_prixmax(@prixmax) if @prixmax.present?
    produits = produits.by_type(@type)
    
    datedebut = Time.current
    datefin   = Time.current
  
    produits_ids = produits.select do |produit|
      produit.statut_disponibilite(datedebut, datefin)[:disponibles] > 0
    end.map(&:id)
  
    Produit.where(id: produits_ids)
  end
  

end
