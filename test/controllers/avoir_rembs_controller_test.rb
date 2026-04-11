require "test_helper"

class AvoirRembsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @avoir_remb = avoir_rembs(:one)
  end

  test "should get index" do
    get admin_avoir_rembs_url
    assert_response :success
  end

  test "should get new" do
    get new_admin_avoir_remb_url
    assert_response :success
  end

  test "should create avoir_remb" do
    assert_difference("AvoirRemb.count") do
      post admin_avoir_rembs_url, params: { avoir_remb: { commande_id: @avoir_remb.commande_id, montant: @avoir_remb.montant, nature: @avoir_remb.nature, type_avoir_remb: @avoir_remb.type_avoir_remb } }
    end

    assert_redirected_to admin_commande_path(AvoirRemb.last.commande)
  end

  test "should get edit" do
    get edit_admin_avoir_remb_url(@avoir_remb)
    assert_response :success
  end

  test "should update avoir_remb" do
    patch admin_avoir_remb_url(@avoir_remb), params: { avoir_remb: { commande_id: @avoir_remb.commande_id, montant: @avoir_remb.montant, nature: @avoir_remb.nature, type_avoir_remb: @avoir_remb.type_avoir_remb } }
    assert_redirected_to admin_commande_path(@avoir_remb.commande)
  end

  test "should destroy avoir_remb" do
    assert_difference("AvoirRemb.count", -1) do
      delete admin_avoir_remb_url(@avoir_remb)
    end

    assert_redirected_to admin_commande_path(@avoir_remb.commande)
  end
end
