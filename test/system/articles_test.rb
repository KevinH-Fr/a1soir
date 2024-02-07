require "application_system_test_case"

class ArticlesTest < ApplicationSystemTestCase
  setup do
    @article = articles(:one)
  end

  test "visiting the index" do
    visit articles_url
    assert_selector "h1", text: "Articles"
  end

  test "should create article" do
    visit articles_url
    click_on "New article"

    fill_in "Caution", with: @article.caution
    fill_in "Commande", with: @article.commande_id
    fill_in "Commentaires", with: @article.commentaires
    fill_in "Locvente", with: @article.locvente
    check "Longueduree" if @article.longueduree
    fill_in "Prix", with: @article.prix
    fill_in "Produit", with: @article.produit_id
    fill_in "Quantite", with: @article.quantite
    fill_in "Total", with: @article.total
    fill_in "Totalcaution", with: @article.totalcaution
    click_on "Create Article"

    assert_text "Article was successfully created"
    click_on "Back"
  end

  test "should update Article" do
    visit article_url(@article)
    click_on "Edit this article", match: :first

    fill_in "Caution", with: @article.caution
    fill_in "Commande", with: @article.commande_id
    fill_in "Commentaires", with: @article.commentaires
    fill_in "Locvente", with: @article.locvente
    check "Longueduree" if @article.longueduree
    fill_in "Prix", with: @article.prix
    fill_in "Produit", with: @article.produit_id
    fill_in "Quantite", with: @article.quantite
    fill_in "Total", with: @article.total
    fill_in "Totalcaution", with: @article.totalcaution
    click_on "Update Article"

    assert_text "Article was successfully updated"
    click_on "Back"
  end

  test "should destroy Article" do
    visit article_url(@article)
    click_on "Destroy this article", match: :first

    assert_text "Article was successfully destroyed"
  end
end
