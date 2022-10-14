require "application_system_test_case"

class ModelsousarticlesTest < ApplicationSystemTestCase
  setup do
    @modelsousarticle = modelsousarticles(:one)
  end

  test "visiting the index" do
    visit modelsousarticles_url
    assert_selector "h1", text: "Modelsousarticles"
  end

  test "should create modelsousarticle" do
    visit modelsousarticles_url
    click_on "New modelsousarticle"

    fill_in "Caution", with: @modelsousarticle.caution
    fill_in "Description", with: @modelsousarticle.description
    fill_in "Nature", with: @modelsousarticle.nature
    fill_in "Prix", with: @modelsousarticle.prix
    click_on "Create Modelsousarticle"

    assert_text "Modelsousarticle was successfully created"
    click_on "Back"
  end

  test "should update Modelsousarticle" do
    visit modelsousarticle_url(@modelsousarticle)
    click_on "Edit this modelsousarticle", match: :first

    fill_in "Caution", with: @modelsousarticle.caution
    fill_in "Description", with: @modelsousarticle.description
    fill_in "Nature", with: @modelsousarticle.nature
    fill_in "Prix", with: @modelsousarticle.prix
    click_on "Update Modelsousarticle"

    assert_text "Modelsousarticle was successfully updated"
    click_on "Back"
  end

  test "should destroy Modelsousarticle" do
    visit modelsousarticle_url(@modelsousarticle)
    click_on "Destroy this modelsousarticle", match: :first

    assert_text "Modelsousarticle was successfully destroyed"
  end
end
