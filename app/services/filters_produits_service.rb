class FiltersProduitsService
  def initialize(categorie, taille, couleur, prixmax, type)
    @categorie = CategorieProduit.find(categorie) if categorie.present?
    @taille = taille
    @couleur = couleur
    @prixmax = prixmax
    @type = type

  end

  def call
    puts " __________ call filter service: categorie #{@categorie} _______"
    puts " __________ call filter service: taille #{@taille} _______"
    puts " __________ call filter service: couleur #{@couleur} _______"
    puts " __________ call filter service: prixmax #{@prixmax} _______"
    puts " __________ call filter service: type #{@type} _______"

    produits = Produit.eshop_diffusion
    produits = @categorie.produits if @categorie.present?
    produits = produits.where(taille: @taille) if @taille.present?
    produits = produits.where(couleur: @couleur) if @couleur.present?
    produits = produits.where("prixvente <= ? OR prixlocation <= ?", @prixmax, @prixmax) if @prixmax.present?
  
    if @type == "Vente"
      produits = produits.where("prixvente > 0")
    elsif @type == "Location"
      produits = produits.where("prixlocation > 0")
    end
    
    produits
  end
end
