require "test_helper"

class ModelsousarticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @modelsousarticle = modelsousarticles(:one)
  end

  test "should get index" do
    get modelsousarticles_url
    assert_response :success
  end

  test "should get new" do
    get new_modelsousarticle_url
    assert_response :success
  end

  test "should create modelsousarticle" do
    assert_difference("Modelsousarticle.count") do
      post modelsousarticles_url, params: { modelsousarticle: { caution: @modelsousarticle.caution, description: @modelsousarticle.description, nature: @modelsousarticle.nature, prix: @modelsousarticle.prix } }
    end

    assert_redirected_to modelsousarticle_url(Modelsousarticle.last)
  end

  test "should show modelsousarticle" do
    get modelsousarticle_url(@modelsousarticle)
    assert_response :success
  end

  test "should get edit" do
    get edit_modelsousarticle_url(@modelsousarticle)
    assert_response :success
  end

  test "should update modelsousarticle" do
    patch modelsousarticle_url(@modelsousarticle), params: { modelsousarticle: { caution: @modelsousarticle.caution, description: @modelsousarticle.description, nature: @modelsousarticle.nature, prix: @modelsousarticle.prix } }
    assert_redirected_to modelsousarticle_url(@modelsousarticle)
  end

  test "should destroy modelsousarticle" do
    assert_difference("Modelsousarticle.count", -1) do
      delete modelsousarticle_url(@modelsousarticle)
    end

    assert_redirected_to modelsousarticles_url
  end
end
