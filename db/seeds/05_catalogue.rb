# frozen_string_literal: true

Seeds::Helpers.log("05", "Produits démo")

fournisseur = Fournisseur.find_by!(nom: "Fournisseur démo")

cat = ->(nom) { Seeds::Helpers.find_nom!(CategorieProduit, nom) }
type = ->(nom) { Seeds::Helpers.find_nom!(TypeProduit, nom) }
couleur = ->(nom) { Seeds::Helpers.find_nom!(Couleur, nom) }
taille = ->(nom) { Seeds::Helpers.find_nom!(Taille, nom) }

# SKU uniques (commandes 06 s'appuient sur ces noms).
singletons = [
  {
    nom: "Robe soirée démo",
    prixvente: 120, prixlocation: 80, quantite: 12,
    type: type.call("robe"), categories: [cat.call("robe")],
    couleur: couleur.call("noir"), taille: taille.call("m"), eshop: true
  },
  {
    nom: "Costume smoking démo",
    prixvente: 150, prixlocation: 90, quantite: 10,
    type: type.call("costume"), categories: [cat.call("costume")],
    couleur: couleur.call("noir"), taille: taille.call("m"), eshop: true
  },
  {
    nom: "Robe cocktail démo",
    prixvente: 95, prixlocation: 60, quantite: 14,
    type: type.call("robe"), categories: [cat.call("robe")],
    couleur: couleur.call("rouge"), taille: taille.call("s"), eshop: false
  },
  {
    nom: "Robe longue ivoire",
    prixvente: 280, prixlocation: 140, quantite: 8,
    type: type.call("robe"), categories: [cat.call("robe")],
    couleur: couleur.call("ivoire"), taille: taille.call("38"), eshop: true
  },
  {
    nom: "Robe cocktail champagne",
    prixvente: 160, prixlocation: 95, quantite: 10,
    type: type.call("robe"), categories: [cat.call("robe")],
    couleur: couleur.call("champagne"), taille: taille.call("40"), eshop: true
  },
  {
    nom: "Costume marine classique",
    prixvente: 220, prixlocation: 110, quantite: 8,
    type: type.call("costume"), categories: [cat.call("costume")],
    couleur: couleur.call("marine"), taille: taille.call("l"), eshop: true
  },
  {
    nom: "Costume bordeaux cérémonie",
    prixvente: 190, prixlocation: 100, quantite: 8,
    type: type.call("costume"), categories: [cat.call("costume")],
    couleur: couleur.call("bordeaux"), taille: taille.call("xl"), eshop: false
  },
  {
    nom: "Chemise blanche smoking",
    prixvente: 65, prixlocation: 25, quantite: 20,
    type: type.call("chemise"), categories: [cat.call("chemise")],
    couleur: couleur.call("blanc"), taille: taille.call("m"), eshop: true
  },
  {
    nom: "Pantalon noir slim",
    prixvente: 85, prixlocation: 35, quantite: 16,
    type: type.call("pantalon"), categories: [cat.call("pantalon")],
    couleur: couleur.call("noir"), taille: taille.call("42"), eshop: false
  },
  {
    nom: "Veste smoking anthracite",
    prixvente: 175, prixlocation: 85, quantite: 10,
    type: type.call("veste"), categories: [cat.call("veste")],
    couleur: couleur.call("gris"), taille: taille.call("l"), eshop: true
  },
  {
    nom: "Escarpins vernis noirs",
    prixvente: 90, prixlocation: 40, quantite: 12,
    type: type.call("chaussures"), categories: [cat.call("chaussures")],
    couleur: couleur.call("noir"), taille: taille.call("38"), eshop: true
  },
  {
    nom: "Souliers cuir marron",
    prixvente: 110, prixlocation: 45, quantite: 10,
    type: type.call("chaussures"), categories: [cat.call("chaussures")],
    couleur: couleur.call("beige"), taille: taille.call("42"), eshop: false
  },
  {
    nom: "Collier cristal soirée",
    prixvente: 45, prixlocation: 20, quantite: 24,
    type: type.call("bijoux"), categories: [cat.call("bijoux"), cat.call("accessoire")],
    couleur: couleur.call("or"), taille: taille.call("unique"), eshop: true
  },
  {
    nom: "Ceinture satin rose",
    prixvente: 30, prixlocation: 12, quantite: 18,
    type: type.call("ceinture"), categories: [cat.call("accessoire")],
    couleur: couleur.call("rose"), taille: taille.call("m"), eshop: false
  },
  {
    nom: "Robe lavande cocktail",
    prixvente: 130, prixlocation: 75, quantite: 8,
    type: type.call("robe"), categories: [cat.call("robe")],
    couleur: couleur.call("lavande"), taille: taille.call("36"), eshop: true
  }
]

# Même nom = même handle → variantes couleur/taille regroupées sur la fiche.
families = [
  {
    nom: "Robe sirène sequins",
    description: "Robe longue sirène brodée sequins, encolure cœur.",
    type: "robe", categories: %w[robe],
    prixvente: 240, prixlocation: 125, prixachat: 90,
    ancien_prixvente: 290, poids: 1600,
    couleurs: %w[noir rouge champagne], tailles: %w[36 38 40],
    quantite: 14, eshop: true, coup_de_coeur: true
  },
  {
    nom: "Robe cocktail velours",
    description: "Robe courte velours stretch, manches trois-quarts.",
    type: "robe", categories: %w[robe],
    prixvente: 145, prixlocation: 80, prixachat: 55,
    poids: 900,
    couleurs: %w[bordeaux vert], tailles: %w[36 38 40],
    quantite: 12, eshop: true
  },
  {
    nom: "Costume trois pièces",
    description: "Costume cérémonie veste, pantalon et gilet.",
    type: "costume", categories: %w[costume],
    prixvente: 260, prixlocation: 130, prixachat: 110,
    poids: 2200,
    couleurs: %w[noir marine gris], tailles: %w[m l xl],
    quantite: 10, eshop: true, coup_de_coeur: true
  },
  {
    nom: "Chemise plastron",
    description: "Chemise smoking plastron plissé, poignets mousquetaires.",
    type: "chemise", categories: %w[chemise],
    prixvente: 70, prixlocation: 28, prixachat: 22,
    poids: 350,
    couleurs: %w[blanc ivoire], tailles: %w[s m l],
    quantite: 18, eshop: true
  },
  {
    nom: "Pantalon smoking",
    description: "Pantalon satiné coupe droite, galon de côté.",
    type: "pantalon", categories: %w[pantalon],
    prixvente: 95, prixlocation: 40, prixachat: 35,
    poids: 700,
    couleurs: %w[noir marine], tailles: %w[40 42 44],
    quantite: 12, eshop: true
  },
  {
    nom: "Veste smoking satin",
    description: "Veste revers satin, un bouton.",
    type: "veste", categories: %w[veste],
    prixvente: 185, prixlocation: 90, prixachat: 70,
    poids: 1100,
    couleurs: %w[noir bordeaux], tailles: %w[m l],
    quantite: 8, eshop: false
  },
  {
    nom: "Escarpins satin",
    description: "Escarpins bout rond, talon 8 cm.",
    type: "chaussures", categories: %w[chaussures],
    prixvente: 95, prixlocation: 42, prixachat: 32,
    poids: 600,
    couleurs: %w[noir rose ivoire], tailles: %w[36 38 40],
    quantite: 10, eshop: true
  },
  {
    nom: "Collier perles nacrées",
    description: "Collier une rangée, fermoir métal.",
    type: "bijoux", categories: %w[bijoux accessoire],
    prixvente: 55, prixlocation: 22, prixachat: 18,
    poids: 120,
    couleurs: %w[blanc or], tailles: %w[unique],
    quantite: 20, eshop: true
  },
  {
    nom: "Ceinture strass",
    description: "Ceinture fine, boucle strass.",
    type: "ceinture", categories: %w[accessoire],
    prixvente: 35, prixlocation: 14, prixachat: 10,
    poids: 180,
    couleurs: %w[noir or], tailles: %w[s m l],
    quantite: 15, eshop: true
  }
]

upsert_produit = lambda do |attrs|
  produit = Produit.find_or_initialize_by(reffrs: attrs[:reffrs])
  produit.assign_attributes(
    nom: attrs[:nom],
    description: attrs[:description],
    prixvente: attrs[:prixvente],
    prixlocation: attrs[:prixlocation],
    prixachat: attrs[:prixachat],
    ancien_prixvente: attrs[:ancien_prixvente],
    quantite: attrs[:quantite],
    type_produit: attrs[:type],
    fournisseur: fournisseur,
    couleur: attrs[:couleur],
    taille: attrs[:taille],
    actif: true,
    eshop: attrs[:eshop],
    poids: attrs[:poids],
    coup_de_coeur: attrs[:coup_de_coeur] || false,
    coup_de_coeur_position: attrs[:coup_de_coeur_position]
  )
  produit.save!
  attrs[:categories].each do |categorie|
    produit.categorie_produits << categorie unless produit.categorie_produits.include?(categorie)
  end
  produit
end

attach_swatch = lambda do |produit|
  return if produit.image1.attached?

  hex = produit.couleur&.couleur_code.to_s.delete("#")
  return if hex.length != 6

  rgb = hex.scan(/../).map { |part| part.to_i(16) }
  png = Seeds::Helpers.solid_png(320, 400, *rgb)
  produit.image1.attach(
    io: StringIO.new(png),
    filename: "#{produit.reffrs}.png",
    content_type: "image/png"
  )
rescue StandardError => e
  Seeds::Helpers.log("05", "Image ignorée (#{produit.reffrs}): #{e.message}")
end

created = []

# QR déjà skippé sur le volume historique : ici aussi, sinon ~70 PNG Cloudinary.
Produit.skip_callback(:create, :after, :generate_qr)
begin
  singletons.each do |attrs|
    created << upsert_produit.call(
      attrs.merge(reffrs: "SEED-#{attrs[:nom].parameterize}")
    )
  end

  families.each do |family|
    categories = family[:categories].map { |nom| cat.call(nom) }
    type_produit = type.call(family[:type])

    family[:couleurs].each_with_index do |couleur_nom, color_index|
      family[:tailles].each do |taille_nom|
        qty = family[:quantite]
        # Une taille en rupture pour tester le listing.
        qty = 0 if family[:nom] == "Robe sirène sequins" && couleur_nom == "rouge" && taille_nom == "40"

        created << upsert_produit.call(
          nom: family[:nom],
          description: family[:description],
          reffrs: "SEED-#{family[:nom].parameterize}-#{couleur_nom}-#{taille_nom}",
          prixvente: family[:prixvente],
          prixlocation: family[:prixlocation],
          prixachat: family[:prixachat],
          ancien_prixvente: family[:ancien_prixvente],
          quantite: qty,
          type: type_produit,
          categories: categories,
          couleur: couleur.call(couleur_nom),
          taille: taille.call(taille_nom),
          eshop: family[:eshop],
          poids: family[:poids],
          coup_de_coeur: family[:coup_de_coeur] && color_index.zero? && taille_nom == family[:tailles].first,
          coup_de_coeur_position: family[:coup_de_coeur] && color_index.zero? && taille_nom == family[:tailles].first ? (family[:nom].include?("Robe") ? 1 : 2) : nil
        )
      end
    end
  end
ensure
  Produit.set_callback(:create, :after, :generate_qr)
end

# Deux pastilles couleur (le shop a déjà un fallback sans photo).
%w[
  SEED-robe-sirene-sequins-noir-36
  SEED-costume-trois-pieces-noir-m
].each do |reffrs|
  produit = created.find { |p| p.reffrs == reffrs }
  attach_swatch.call(produit) if produit
end

Seeds::Helpers.log(
  "05",
  "#{created.size} SKU (#{created.map(&:handle).uniq.size} modèles, #{created.count { |p| p.quantite.to_i.positive? }} en stock)"
)
