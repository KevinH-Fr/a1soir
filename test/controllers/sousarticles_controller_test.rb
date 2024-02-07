require "test_helper"

class SousarticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sousarticle = sousarticles(:one)
  end

  test "should get index" do
    get sousarticles_url
    assert_response :success
  end

  test "should get new" do
    get new_sousarticle_url
    assert_response :success
  end

  test "should create sousarticle" do
    assert_difference("Sousarticle.count") do
      post sousarticles_url, params: { sousarticle: { article_id: @sousarticle.article_id, caution: @sousarticle.caution, commentaires: @sousarticle.commentaires, description: @sousarticle.description, nature: @sousarticle.nature, prix: @sousarticle.prix, produit_id: @sousarticle.produit_id } }
    end

    assert_redirected_to sousarticle_url(Sousarticle.last)
  end

  test "should show sousarticle" do
    get sousarticle_url(@sousarticle)
    assert_response :success
  end

  test "should get edit" do
    get edit_sousarticle_url(@sousarticle)
    assert_response :success
  end

  test "should update sousarticle" do
    patch sousarticle_url(@sousarticle), params: { sousarticle: { article_id: @sousarticle.article_id, caution: @sousarticle.caution, commentaires: @sousarticle.commentaires, description: @sousarticle.description, nature: @sousarticle.nature, prix: @sousarticle.prix, produit_id: @sousarticle.produit_id } }
    assert_redirected_to sousarticle_url(@sousarticle)
  end

  test "should destroy sousarticle" do
    assert_difference("Sousarticle.count", -1) do
      delete sousarticle_url(@sousarticle)
    end

    assert_redirected_to sousarticles_url
  end
end
