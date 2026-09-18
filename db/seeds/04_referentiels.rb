# frozen_string_literal: true

Seeds::Helpers.log("04", "Référentiels catalogue")

%w[
  Noir Blanc Rouge Bleu Bordeaux Champagne Vert Rose Gris Ivoire Marine Or Beige Lavande
].each do |nom|
  Seeds::Helpers.find_or_create_nom!(Couleur, nom)
end

%w[XXS XS S M L XL XXL 34 36 38 40 42 44 46 48 Unique].each do |nom|
  Seeds::Helpers.find_or_create_nom!(Taille, nom)
end

[
  ["robe", false],
  ["costume", false],
  ["accessoire", false],
  ["chaussures", false],
  ["chemise", false],
  ["pantalon", false],
  ["bijoux", false],
  ["veste", false],
  ["service", true]
].each do |nom, service|
  Seeds::Helpers.find_or_create_nom!(CategorieProduit, nom, service: service)
end

%w[robe costume accessoire chaussures chemise pantalon bijoux veste ceinture].each do |nom|
  Seeds::Helpers.find_or_create_nom!(TypeProduit, nom)
end

Fournisseur.find_or_create_by!(nom: "Fournisseur démo") do |f|
  f.mail = "fournisseur@dev.a1soir.local"
  f.tel = "0100000000"
end
