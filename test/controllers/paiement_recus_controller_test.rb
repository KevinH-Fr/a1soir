require "test_helper"

class PaiementRecusControllerTest < ActionDispatch::IntegrationTest
  setup do
    @paiement_recu = paiement_recus(:one)
  end

  test "should get index" do
    get paiement_recus_url
    assert_response :success
  end

  test "should get new" do
    get new_paiement_recu_url
    assert_response :success
  end

  test "should create paiement_recu" do
    assert_difference("PaiementRecu.count") do
      post paiement_recus_url, params: { paiement_recu: { commande_id: @paiement_recu.commande_id, commentaires: @paiement_recu.commentaires, montant: @paiement_recu.montant, moyen: @paiement_recu.moyen, typepaiement: @paiement_recu.typepaiement } }
    end

    assert_redirected_to paiement_recu_url(PaiementRecu.last)
  end

  test "should show paiement_recu" do
    get paiement_recu_url(@paiement_recu)
    assert_response :success
  end

  test "should get edit" do
    get edit_paiement_recu_url(@paiement_recu)
    assert_response :success
  end

  test "should update paiement_recu" do
    patch paiement_recu_url(@paiement_recu), params: { paiement_recu: { commande_id: @paiement_recu.commande_id, commentaires: @paiement_recu.commentaires, montant: @paiement_recu.montant, moyen: @paiement_recu.moyen, typepaiement: @paiement_recu.typepaiement } }
    assert_redirected_to paiement_recu_url(@paiement_recu)
  end

  test "should destroy paiement_recu" do
    assert_difference("PaiementRecu.count", -1) do
      delete paiement_recu_url(@paiement_recu)
    end

    assert_redirected_to paiement_recus_url
  end
end
