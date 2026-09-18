# frozen_string_literal: true

Seeds::Helpers.log("07", "RDV et contenu boutique")

[
  ["Découverte", 45],
  ["Essayage", 60],
  ["Retouche", 30]
].each do |code, minutes|
  TypeRdv.find_or_create_by!(code: code) do |t|
    t.duree_base_minutes = minutes
  end
end

unless ParametreRdv.exists?
  creneaux = ParametreRdv::DEFAULT_CRENEAUX.join(",")
  ParametreRdv.create!(
    nom: "Boutique principale",
    minutes_par_personne_supp: 15,
    creneaux_lundi: creneaux,
    creneaux_mardi: creneaux,
    creneaux_mercredi: creneaux,
    creneaux_jeudi: creneaux,
    creneaux_vendredi: creneaux,
    creneaux_samedi: creneaux,
    creneaux_dimanche: ""
  )
end

Texte.find_or_create_by!(titre: "Boutique démo") do |t|
  t.adresse = "1 rue de la Démo, 75000 Paris"
end
