require "application_system_test_case"

class CategorieProduitsTest < ApplicationSystemTestCase
  setup do
    @categorie_produit = categorie_produits(:one)
  end

  test "visiting the index" do
    visit categorie_produits_url
    assert_selector "h1", text: "Categorie produits"
  end

  test "should create categorie produit" do
    visit categorie_produits_url
    click_on "New categorie produit"

    fill_in "Label", with: @categorie_produit.label
    fill_in "Nom", with: @categorie_produit.nom
    fill_in "Texte annonce", with: @categorie_produit.texte_annonce
    click_on "Create Categorie produit"

    assert_text "Categorie produit was successfully created"
    click_on "Back"
  end

  test "should update Categorie produit" do
    visit categorie_produit_url(@categorie_produit)
    click_on "Edit this categorie produit", match: :first

    fill_in "Label", with: @categorie_produit.label
    fill_in "Nom", with: @categorie_produit.nom
    fill_in "Texte annonce", with: @categorie_produit.texte_annonce
    click_on "Update Categorie produit"

    assert_text "Categorie produit was successfully updated"
    click_on "Back"
  end

  test "should destroy Categorie produit" do
    visit categorie_produit_url(@categorie_produit)
    click_on "Destroy this categorie produit", match: :first

    assert_text "Categorie produit was successfully destroyed"
  end
end
