require "test_helper"

class TextesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @texte = textes(:one)
  end

  test "should get index" do
    get textes_url
    assert_response :success
  end

  test "should get new" do
    get new_texte_url
    assert_response :success
  end

  test "should create texte" do
    assert_difference("Texte.count") do
      post textes_url, params: { texte: { titre: @texte.titre } }
    end

    assert_redirected_to texte_url(Texte.last)
  end

  test "should show texte" do
    get texte_url(@texte)
    assert_response :success
  end

  test "should get edit" do
    get edit_texte_url(@texte)
    assert_response :success
  end

  test "should update texte" do
    patch texte_url(@texte), params: { texte: { titre: @texte.titre } }
    assert_redirected_to texte_url(@texte)
  end

  test "should destroy texte" do
    assert_difference("Texte.count", -1) do
      delete texte_url(@texte)
    end

    assert_redirected_to textes_url
  end
end
