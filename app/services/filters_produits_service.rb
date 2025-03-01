class FiltersProduitsService
  def initialize(categorie, taille, couleur)
    @categorie = CategorieProduit.find(categorie) if categorie.present?
    @taille = taille
    @couleur = couleur

  end

  def call
    puts " __________ call filter service: params #{@categorie} _______"
    puts " __________ call filter service: params #{@taille} _______"
    puts " __________ call filter service: params #{@couleur} _______"

    produits = Produit.eshop_diffusion
    produits = @categorie.produits if @categorie.present?
    produits = produits.where(taille: @taille) if @taille.present?
    produits = produits.where(couleur: @couleur) if @couleur.present?

    produits
  end
end
