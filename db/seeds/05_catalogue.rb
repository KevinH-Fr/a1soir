# frozen_string_literal: true

Seeds::Helpers.log("05", "Produits démo")

fournisseur = Fournisseur.find_by!(nom: "Fournisseur démo")

cat = ->(nom) { Seeds::Helpers.find_nom!(CategorieProduit, nom) }
type = ->(nom) { Seeds::Helpers.find_nom!(TypeProduit, nom) }
couleur = ->(nom) { Seeds::Helpers.find_nom!(Couleur, nom) }
taille = ->(nom) { Seeds::Helpers.find_nom!(Taille, nom) }

catalogue = [
  {
    nom: "Robe soirée démo",
    prixvente: 120, prixlocation: 80, quantite: 3,
    type: type.call("robe"), categories: [cat.call("robe")],
    couleur: couleur.call("noir"), taille: taille.call("m"), eshop: true
  },
  {
    nom: "Costume smoking démo",
    prixvente: 150, prixlocation: 90, quantite: 2,
    type: type.call("costume"), categories: [cat.call("costume")],
    couleur: couleur.call("noir"), taille: taille.call("m"), eshop: true
  },
  {
    nom: "Robe cocktail démo",
    prixvente: 95, prixlocation: 60, quantite: 4,
    type: type.call("robe"), categories: [cat.call("robe")],
    couleur: couleur.call("rouge"), taille: taille.call("s"), eshop: false
  },
  {
    nom: "Robe longue ivoire",
    prixvente: 280, prixlocation: 140, quantite: 2,
    type: type.call("robe"), categories: [cat.call("robe")],
    couleur: couleur.call("ivoire"), taille: taille.call("38"), eshop: true
  },
  {
    nom: "Robe cocktail champagne",
    prixvente: 160, prixlocation: 95, quantite: 3,
    type: type.call("robe"), categories: [cat.call("robe")],
    couleur: couleur.call("champagne"), taille: taille.call("40"), eshop: true
  },
  {
    nom: "Costume marine classique",
    prixvente: 220, prixlocation: 110, quantite: 2,
    type: type.call("costume"), categories: [cat.call("costume")],
    couleur: couleur.call("marine"), taille: taille.call("l"), eshop: true
  },
  {
    nom: "Costume bordeaux cérémonie",
    prixvente: 190, prixlocation: 100, quantite: 2,
    type: type.call("costume"), categories: [cat.call("costume")],
    couleur: couleur.call("bordeaux"), taille: taille.call("xl"), eshop: false
  },
  {
    nom: "Chemise blanche smoking",
    prixvente: 65, prixlocation: 25, quantite: 8,
    type: type.call("chemise"), categories: [cat.call("chemise")],
    couleur: couleur.call("blanc"), taille: taille.call("m"), eshop: true
  },
  {
    nom: "Pantalon noir slim",
    prixvente: 85, prixlocation: 35, quantite: 5,
    type: type.call("pantalon"), categories: [cat.call("pantalon")],
    couleur: couleur.call("noir"), taille: taille.call("42"), eshop: false
  },
  {
    nom: "Veste smoking anthracite",
    prixvente: 175, prixlocation: 85, quantite: 3,
    type: type.call("veste"), categories: [cat.call("veste")],
    couleur: couleur.call("gris"), taille: taille.call("l"), eshop: true
  },
  {
    nom: "Escarpins vernis noirs",
    prixvente: 90, prixlocation: 40, quantite: 4,
    type: type.call("chaussures"), categories: [cat.call("chaussures")],
    couleur: couleur.call("noir"), taille: taille.call("38"), eshop: true
  },
  {
    nom: "Souliers cuir marron",
    prixvente: 110, prixlocation: 45, quantite: 3,
    type: type.call("chaussures"), categories: [cat.call("chaussures")],
    couleur: couleur.call("beige"), taille: taille.call("42"), eshop: false
  },
  {
    nom: "Collier cristal soirée",
    prixvente: 45, prixlocation: 20, quantite: 10,
    type: type.call("bijoux"), categories: [cat.call("bijoux"), cat.call("accessoire")],
    couleur: couleur.call("or"), taille: taille.call("unique"), eshop: true
  },
  {
    nom: "Ceinture satin rose",
    prixvente: 30, prixlocation: 12, quantite: 6,
    type: type.call("ceinture"), categories: [cat.call("accessoire")],
    couleur: couleur.call("rose"), taille: taille.call("m"), eshop: false
  },
  {
    nom: "Robe lavande cocktail",
    prixvente: 130, prixlocation: 75, quantite: 2,
    type: type.call("robe"), categories: [cat.call("robe")],
    couleur: couleur.call("lavande"), taille: taille.call("36"), eshop: true
  }
]

catalogue.each do |attrs|
  produit = Produit.find_or_initialize_by(nom: attrs[:nom])
  produit.assign_attributes(
    prixvente: attrs[:prixvente],
    prixlocation: attrs[:prixlocation],
    quantite: attrs[:quantite],
    type_produit: attrs[:type],
    fournisseur: fournisseur,
    couleur: attrs[:couleur],
    taille: attrs[:taille],
    actif: true,
    eshop: attrs[:eshop],
    reffrs: "SEED-#{attrs[:nom].parameterize}"
  )
  produit.save!
  attrs[:categories].each do |categorie|
    produit.categorie_produits << categorie unless produit.categorie_produits.include?(categorie)
  end
end
