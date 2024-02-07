require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @article = articles(:one)
  end

  test "should get index" do
    get articles_url
    assert_response :success
  end

  test "should get new" do
    get new_article_url
    assert_response :success
  end

  test "should create article" do
    assert_difference("Article.count") do
      post articles_url, params: { article: { caution: @article.caution, commande_id: @article.commande_id, commentaires: @article.commentaires, locvente: @article.locvente, longueduree: @article.longueduree, prix: @article.prix, produit_id: @article.produit_id, quantite: @article.quantite, total: @article.total, totalcaution: @article.totalcaution } }
    end

    assert_redirected_to article_url(Article.last)
  end

  test "should show article" do
    get article_url(@article)
    assert_response :success
  end

  test "should get edit" do
    get edit_article_url(@article)
    assert_response :success
  end

  test "should update article" do
    patch article_url(@article), params: { article: { caution: @article.caution, commande_id: @article.commande_id, commentaires: @article.commentaires, locvente: @article.locvente, longueduree: @article.longueduree, prix: @article.prix, produit_id: @article.produit_id, quantite: @article.quantite, total: @article.total, totalcaution: @article.totalcaution } }
    assert_redirected_to article_url(@article)
  end

  test "should destroy article" do
    assert_difference("Article.count", -1) do
      delete article_url(@article)
    end

    assert_redirected_to articles_url
  end
end
