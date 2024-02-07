require "application_system_test_case"

class FournisseursTest < ApplicationSystemTestCase
  setup do
    @fournisseur = fournisseurs(:one)
  end

  test "visiting the index" do
    visit fournisseurs_url
    assert_selector "h1", text: "Fournisseurs"
  end

  test "should create fournisseur" do
    visit fournisseurs_url
    click_on "New fournisseur"

    fill_in "Contact", with: @fournisseur.contact
    fill_in "Mail", with: @fournisseur.mail
    fill_in "Nom", with: @fournisseur.nom
    fill_in "Notes", with: @fournisseur.notes
    fill_in "Site", with: @fournisseur.site
    fill_in "Tel", with: @fournisseur.tel
    click_on "Create Fournisseur"

    assert_text "Fournisseur was successfully created"
    click_on "Back"
  end

  test "should update Fournisseur" do
    visit fournisseur_url(@fournisseur)
    click_on "Edit this fournisseur", match: :first

    fill_in "Contact", with: @fournisseur.contact
    fill_in "Mail", with: @fournisseur.mail
    fill_in "Nom", with: @fournisseur.nom
    fill_in "Notes", with: @fournisseur.notes
    fill_in "Site", with: @fournisseur.site
    fill_in "Tel", with: @fournisseur.tel
    click_on "Update Fournisseur"

    assert_text "Fournisseur was successfully updated"
    click_on "Back"
  end

  test "should destroy Fournisseur" do
    visit fournisseur_url(@fournisseur)
    click_on "Destroy this fournisseur", match: :first

    assert_text "Fournisseur was successfully destroyed"
  end
end
