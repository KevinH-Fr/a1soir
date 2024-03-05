require "application_system_test_case"

class TypeProduitsTest < ApplicationSystemTestCase
  setup do
    @type_produit = type_produits(:one)
  end

  test "visiting the index" do
    visit type_produits_url
    assert_selector "h1", text: "Type produits"
  end

  test "should create type produit" do
    visit type_produits_url
    click_on "New type produit"

    fill_in "Nom", with: @type_produit.nom
    click_on "Create Type produit"

    assert_text "Type produit was successfully created"
    click_on "Back"
  end

  test "should update Type produit" do
    visit type_produit_url(@type_produit)
    click_on "Edit this type produit", match: :first

    fill_in "Nom", with: @type_produit.nom
    click_on "Update Type produit"

    assert_text "Type produit was successfully updated"
    click_on "Back"
  end

  test "should destroy Type produit" do
    visit type_produit_url(@type_produit)
    click_on "Destroy this type produit", match: :first

    assert_text "Type produit was successfully destroyed"
  end
end
