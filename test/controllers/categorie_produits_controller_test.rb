require "test_helper"

class CategorieProduitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @categorie_produit = categorie_produits(:one)
  end

  test "should get index" do
    get categorie_produits_url
    assert_response :success
  end

  test "should get new" do
    get new_categorie_produit_url
    assert_response :success
  end

  test "should create categorie_produit" do
    assert_difference("CategorieProduit.count") do
      post categorie_produits_url, params: { categorie_produit: { label: @categorie_produit.label, nom: @categorie_produit.nom, texte_annonce: @categorie_produit.texte_annonce } }
    end

    assert_redirected_to categorie_produit_url(CategorieProduit.last)
  end

  test "should show categorie_produit" do
    get categorie_produit_url(@categorie_produit)
    assert_response :success
  end

  test "should get edit" do
    get edit_categorie_produit_url(@categorie_produit)
    assert_response :success
  end

  test "should update categorie_produit" do
    patch categorie_produit_url(@categorie_produit), params: { categorie_produit: { label: @categorie_produit.label, nom: @categorie_produit.nom, texte_annonce: @categorie_produit.texte_annonce } }
    assert_redirected_to categorie_produit_url(@categorie_produit)
  end

  test "should destroy categorie_produit" do
    assert_difference("CategorieProduit.count", -1) do
      delete categorie_produit_url(@categorie_produit)
    end

    assert_redirected_to categorie_produits_url
  end
end
