# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Costumes et déguisements", type: :request do
  before { allow(GenerateQr).to receive(:call) }

  let!(:taille_mariee) { Taille.create!(nom: "T38ROBE") }
  let!(:taille_costume) { Taille.create!(nom: "T54COST") }
  let!(:couleur) { Couleur.create!(nom: "Pourpre costume") }
  let!(:type_mariee) { TypeProduit.create!(nom: "robe ceremonie") }
  let!(:type_costume) { TypeProduit.create!(nom: "habit de cour") }
  let!(:categorie) { CategorieProduit.create!(nom: "robes de mariee spec") }
  let!(:epoque) { RubriqueCostume.create!(nom: "XVIIIe siècle", groupe: "Époque", position: 1) }
  let!(:marquis) { RubriqueCostume.create!(nom: "Marquis et marquise", groupe: "Personnage", position: 2) }
  let!(:pirate) { RubriqueCostume.create!(nom: "Pirate", groupe: "Personnage", position: 3) }

  let!(:robe) do
    Produit.create!(
      nom: "Robe mariee catalogue",
      prixvente: 100,
      eshop: true,
      actif: true,
      today_availability: true,
      quantite: 1,
      taille: taille_mariee,
      type_produit: type_mariee,
      categorie_produits: [categorie]
    )
  end

  let!(:habit) do
    produit = Produit.create!(
      nom: "Habit de marquise",
      prixvente: 80,
      eshop: true,
      actif: true,
      today_availability: true,
      quantite: 1,
      catalogue: Produit::CATALOGUE_COSTUME_EPOQUE_DEGUISEMENTS,
      taille: taille_costume,
      couleur: couleur,
      type_produit: type_costume,
      categorie_produit_ids: [categorie.id]
    )
    produit.rubrique_costumes << [epoque, marquis]
    produit
  end

  def attach_image(produit)
    produit.image1.attach(
      io: StringIO.new("image"),
      filename: "costume.jpg",
      content_type: "image/jpeg"
    )
  end

  it "retire le costume des produits mariage, de ses filtres et des produits similaires" do
    get "/fr/produits"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Robe mariee catalogue")
    expect(response.body).not_to include("Habit de marquise")
    expect(response.body).to include("T38ROBE")
    expect(response.body).not_to include("T54COST")
    expect(response.body).not_to include("habit de cour")
    expect(response.body).not_to include("Marquis et marquise")
    expect(robe.similar_products.map(&:id)).not_to include(habit.id)
  end

  it "liste seulement les costumes, avec les rubriques, tailles et couleurs de ce catalogue" do
    get "/fr/produits_costumes_deguisements"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Habit de marquise")
    expect(response.body).not_to include("Robe mariee catalogue")
    expect(response.body).to include("T54COST")
    expect(response.body).not_to include("T38ROBE")
    expect(response.body).to include("Marquis et marquise")
    expect(response.body).to include("XVIIIe siècle")
    expect(response.body).not_to include("Pirate")
    expect(response.body).not_to include("filtres-categorie")
    expect(response.body).not_to include("filtres-type-produit")
  end

  it "retrouve un costume dans chacune de ses rubriques" do
    get "/fr/produits_costumes_deguisements", params: { rubrique: epoque.id }
    expect(response.body).to include("Habit de marquise")

    get "/fr/produits_costumes_deguisements", params: { rubrique: marquis.id }
    expect(response.body).to include("Habit de marquise")

    get "/fr/produits_costumes_deguisements", params: { rubrique: pirate.id }
    expect(response.body).not_to include("Habit de marquise")
  end

  it "vide les catégories mariage ou les rubriques selon le catalogue" do
    expect(habit.reload.categorie_produits).to be_empty
    expect(habit.rubrique_costumes).to contain_exactly(epoque, marquis)

    habit.update!(catalogue: Produit::CATALOGUE_TENUES_MARIAGE_SOIREE)
    expect(habit.reload.rubrique_costumes).to be_empty

    habit.update!(catalogue: Produit::CATALOGUE_COSTUME_EPOQUE_DEGUISEMENTS, rubrique_costume_ids: [marquis.id], categorie_produit_ids: [categorie.id])
    expect(habit.reload.categorie_produits).to be_empty
    expect(habit.rubrique_costumes).to contain_exactly(marquis)
  end

  it "exclut le costume du flux marchand" do
    attach_image(robe)
    attach_image(habit)

    expect(GoogleMerchant::FeedBuilder.feed_scope.where(id: robe.id)).to exist
    expect(GoogleMerchant::FeedBuilder.feed_scope.where(id: habit.id)).to be_empty
  end

  it "redirige l'ancien guide mariage à thème et publie le guide marquis" do
    get "/fr/guides/costume-epoque-mariage-theme"
    expect(response).to redirect_to("/fr/guides/costumes-epoque-histoire-mode")

    get "/fr/guides/costume-marquis-marquise"
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("translation missing")
    expect(response.body).to include("Costumes de marquis et de marquise")
    expect(response.body).not_to include("Robe mariee catalogue")
  end

  it "ouvre la landing depuis le libellé de la collection" do
    get "/fr/costumes-depoque"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Époque")
    expect(response.body).to include("XVIIIe siècle")
    expect(response.body).to include("Personnage")
    expect(response.body).to include("Marquis et marquise")
    expect(response.body).not_to include("Pirate")
    expect(response.body).to include("/fr/produits_costumes_deguisements?rubrique=#{epoque.id}")
    expect(response.body).to include("/fr/produits_costumes_deguisements")
    expect(response.body).to include("/fr/guides/costumes-epoque-histoire-mode")
    expect(response.body).to include("/fr/guides/costume-marquis-marquise")
    expect(response.body).to include("Tous les guides")
  end
end
