require "test_helper"

class CommandesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @commande = commandes(:one)
  end

  test "should get index" do
    get commandes_url
    assert_response :success
  end

  test "should get new" do
    get new_commande_url
    assert_response :success
  end

  test "should create commande" do
    assert_difference("Commande.count") do
      post commandes_url, params: { commande: { client_id: @commande.client_id, commentaires: @commande.commentaires, commentaires_doc: @commande.commentaires_doc, dateevent: @commande.dateevent, debutloc: @commande.debutloc, description: @commande.description, devis: @commande.devis, finloc: @commande.finloc, location: @commande.location, montant: @commande.montant, nom: @commande.nom, profile_id: @commande.profile_id, statutarticles: @commande.statutarticles, typeevent: @commande.typeevent } }
    end

    assert_redirected_to commande_url(Commande.last)
  end

  test "should show commande" do
    get commande_url(@commande)
    assert_response :success
  end

  test "should get edit" do
    get edit_commande_url(@commande)
    assert_response :success
  end

  test "should update commande" do
    patch commande_url(@commande), params: { commande: { client_id: @commande.client_id, commentaires: @commande.commentaires, commentaires_doc: @commande.commentaires_doc, dateevent: @commande.dateevent, debutloc: @commande.debutloc, description: @commande.description, devis: @commande.devis, finloc: @commande.finloc, location: @commande.location, montant: @commande.montant, nom: @commande.nom, profile_id: @commande.profile_id, statutarticles: @commande.statutarticles, typeevent: @commande.typeevent } }
    assert_redirected_to commande_url(@commande)
  end

  test "should destroy commande" do
    assert_difference("Commande.count", -1) do
      delete commande_url(@commande)
    end

    assert_redirected_to commandes_url
  end
end
