require "application_system_test_case"

class ArticleoptionsTest < ApplicationSystemTestCase
  setup do
    @articleoption = articleoptions(:one)
  end

  test "visiting the index" do
    visit articleoptions_url
    assert_selector "h1", text: "Articleoptions"
  end

  test "should create articleoption" do
    visit articleoptions_url
    click_on "New articleoption"

    fill_in "Caution", with: @articleoption.caution
    fill_in "Commande", with: @articleoption.commande_id
    fill_in "Description", with: @articleoption.description
    fill_in "Nature", with: @articleoption.nature
    fill_in "Prix", with: @articleoption.prix
    fill_in "Taille", with: @articleoption.taille
    click_on "Create Articleoption"

    assert_text "Articleoption was successfully created"
    click_on "Back"
  end

  test "should update Articleoption" do
    visit articleoption_url(@articleoption)
    click_on "Edit this articleoption", match: :first

    fill_in "Caution", with: @articleoption.caution
    fill_in "Commande", with: @articleoption.commande_id
    fill_in "Description", with: @articleoption.description
    fill_in "Nature", with: @articleoption.nature
    fill_in "Prix", with: @articleoption.prix
    fill_in "Taille", with: @articleoption.taille
    click_on "Update Articleoption"

    assert_text "Articleoption was successfully updated"
    click_on "Back"
  end

  test "should destroy Articleoption" do
    visit articleoption_url(@articleoption)
    click_on "Destroy this articleoption", match: :first

    assert_text "Articleoption was successfully destroyed"
  end
end
