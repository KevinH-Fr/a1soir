require "application_system_test_case"

class SousarticlesTest < ApplicationSystemTestCase
  setup do
    @sousarticle = sousarticles(:one)
  end

  test "visiting the index" do
    visit sousarticles_url
    assert_selector "h1", text: "Sousarticles"
  end

  test "should create sousarticle" do
    visit sousarticles_url
    click_on "New sousarticle"

    fill_in "Article", with: @sousarticle.article_id
    fill_in "Caution", with: @sousarticle.caution
    fill_in "Commentaires", with: @sousarticle.commentaires
    fill_in "Description", with: @sousarticle.description
    fill_in "Nature", with: @sousarticle.nature
    fill_in "Prix", with: @sousarticle.prix
    fill_in "Produit", with: @sousarticle.produit_id
    click_on "Create Sousarticle"

    assert_text "Sousarticle was successfully created"
    click_on "Back"
  end

  test "should update Sousarticle" do
    visit sousarticle_url(@sousarticle)
    click_on "Edit this sousarticle", match: :first

    fill_in "Article", with: @sousarticle.article_id
    fill_in "Caution", with: @sousarticle.caution
    fill_in "Commentaires", with: @sousarticle.commentaires
    fill_in "Description", with: @sousarticle.description
    fill_in "Nature", with: @sousarticle.nature
    fill_in "Prix", with: @sousarticle.prix
    fill_in "Produit", with: @sousarticle.produit_id
    click_on "Update Sousarticle"

    assert_text "Sousarticle was successfully updated"
    click_on "Back"
  end

  test "should destroy Sousarticle" do
    visit sousarticle_url(@sousarticle)
    click_on "Destroy this sousarticle", match: :first

    assert_text "Sousarticle was successfully destroyed"
  end
end
