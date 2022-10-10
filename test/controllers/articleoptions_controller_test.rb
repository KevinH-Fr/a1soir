require "test_helper"

class ArticleoptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @articleoption = articleoptions(:one)
  end

  test "should get index" do
    get articleoptions_url
    assert_response :success
  end

  test "should get new" do
    get new_articleoption_url
    assert_response :success
  end

  test "should create articleoption" do
    assert_difference("Articleoption.count") do
      post articleoptions_url, params: { articleoption: { caution: @articleoption.caution, commande_id: @articleoption.commande_id, description: @articleoption.description, nature: @articleoption.nature, prix: @articleoption.prix, taille: @articleoption.taille } }
    end

    assert_redirected_to articleoption_url(Articleoption.last)
  end

  test "should show articleoption" do
    get articleoption_url(@articleoption)
    assert_response :success
  end

  test "should get edit" do
    get edit_articleoption_url(@articleoption)
    assert_response :success
  end

  test "should update articleoption" do
    patch articleoption_url(@articleoption), params: { articleoption: { caution: @articleoption.caution, commande_id: @articleoption.commande_id, description: @articleoption.description, nature: @articleoption.nature, prix: @articleoption.prix, taille: @articleoption.taille } }
    assert_redirected_to articleoption_url(@articleoption)
  end

  test "should destroy articleoption" do
    assert_difference("Articleoption.count", -1) do
      delete articleoption_url(@articleoption)
    end

    assert_redirected_to articleoptions_url
  end
end
