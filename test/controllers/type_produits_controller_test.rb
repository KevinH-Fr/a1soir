require "test_helper"

class TypeProduitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @type_produit = type_produits(:one)
  end

  test "should get index" do
    get type_produits_url
    assert_response :success
  end

  test "should get new" do
    get new_type_produit_url
    assert_response :success
  end

  test "should create type_produit" do
    assert_difference("TypeProduit.count") do
      post type_produits_url, params: { type_produit: { nom: @type_produit.nom } }
    end

    assert_redirected_to type_produit_url(TypeProduit.last)
  end

  test "should show type_produit" do
    get type_produit_url(@type_produit)
    assert_response :success
  end

  test "should get edit" do
    get edit_type_produit_url(@type_produit)
    assert_response :success
  end

  test "should update type_produit" do
    patch type_produit_url(@type_produit), params: { type_produit: { nom: @type_produit.nom } }
    assert_redirected_to type_produit_url(@type_produit)
  end

  test "should destroy type_produit" do
    assert_difference("TypeProduit.count", -1) do
      delete type_produit_url(@type_produit)
    end

    assert_redirected_to type_produits_url
  end
end
