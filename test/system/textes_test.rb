require "application_system_test_case"

class TextesTest < ApplicationSystemTestCase
  setup do
    @texte = textes(:one)
  end

  test "visiting the index" do
    visit textes_url
    assert_selector "h1", text: "Textes"
  end

  test "should create texte" do
    visit textes_url
    click_on "New texte"

    fill_in "Titre", with: @texte.titre
    click_on "Create Texte"

    assert_text "Texte was successfully created"
    click_on "Back"
  end

  test "should update Texte" do
    visit texte_url(@texte)
    click_on "Edit this texte", match: :first

    fill_in "Titre", with: @texte.titre
    click_on "Update Texte"

    assert_text "Texte was successfully updated"
    click_on "Back"
  end

  test "should destroy Texte" do
    visit texte_url(@texte)
    click_on "Destroy this texte", match: :first

    assert_text "Texte was successfully destroyed"
  end
end
