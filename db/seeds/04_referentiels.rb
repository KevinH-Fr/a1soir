# frozen_string_literal: true

Seeds::Helpers.log("04", "Référentiels catalogue")

{
  "Noir" => "#111111",
  "Blanc" => "#f4f1ea",
  "Rouge" => "#c1121f",
  "Bleu" => "#1d4e89",
  "Bordeaux" => "#6d071a",
  "Champagne" => "#f3e0b8",
  "Vert" => "#2d6a4f",
  "Rose" => "#e8a0bf",
  "Gris" => "#6c757d",
  "Ivoire" => "#f7f1de",
  "Marine" => "#001f3f",
  "Or" => "#c9a227",
  "Beige" => "#d8c3a5",
  "Lavande" => "#b57edc"
}.each do |nom, code|
  Seeds::Helpers.find_or_create_nom!(Couleur, nom, couleur_code: code)
end

%w[XXS XS S M L XL XXL 32 34 35 36 37 38 39 40 41 42 43 44 46 48 50 52 54 56 58 60 62 Unique].each do |nom|
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
