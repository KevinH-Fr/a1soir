require "application_system_test_case"

class ProduitsTest < ApplicationSystemTestCase
  setup do
    @produit = produits(:one)
  end

  test "visiting the index" do
    visit produits_url
    assert_selector "h1", text: "Produits"
  end

  test "should create produit" do
    visit produits_url
    click_on "New produit"

    fill_in "Categorie produit", with: @produit.categorie_produit_id
    fill_in "Caution", with: @produit.caution
    fill_in "Dateachat", with: @produit.dateachat
    fill_in "Description", with: @produit.description
    fill_in "Fournisseur", with: @produit.fournisseur_id
    fill_in "Handle", with: @produit.handle
    fill_in "Nom", with: @produit.nom
    fill_in "Prixachat", with: @produit.prixachat
    fill_in "Prixlocation", with: @produit.prixlocation
    fill_in "Prixvente", with: @produit.prixvente
    fill_in "Quantite", with: @produit.quantite
    fill_in "Reffrs", with: @produit.reffrs
    click_on "Create Produit"

    assert_text "Produit was successfully created"
    click_on "Back"
  end

  test "should update Produit" do
    visit produit_url(@produit)
    click_on "Edit this produit", match: :first

    fill_in "Categorie produit", with: @produit.categorie_produit_id
    fill_in "Caution", with: @produit.caution
    fill_in "Dateachat", with: @produit.dateachat
    fill_in "Description", with: @produit.description
    fill_in "Fournisseur", with: @produit.fournisseur_id
    fill_in "Handle", with: @produit.handle
    fill_in "Nom", with: @produit.nom
    fill_in "Prixachat", with: @produit.prixachat
    fill_in "Prixlocation", with: @produit.prixlocation
    fill_in "Prixvente", with: @produit.prixvente
    fill_in "Quantite", with: @produit.quantite
    fill_in "Reffrs", with: @produit.reffrs
    click_on "Update Produit"

    assert_text "Produit was successfully updated"
    click_on "Back"
  end

  test "should destroy Produit" do
    visit produit_url(@produit)
    click_on "Destroy this produit", match: :first

    assert_text "Produit was successfully destroyed"
  end
end
