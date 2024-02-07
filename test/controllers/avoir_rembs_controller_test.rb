require "test_helper"

class AvoirRembsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @avoir_remb = avoir_rembs(:one)
  end

  test "should get index" do
    get avoir_rembs_url
    assert_response :success
  end

  test "should get new" do
    get new_avoir_remb_url
    assert_response :success
  end

  test "should create avoir_remb" do
    assert_difference("AvoirRemb.count") do
      post avoir_rembs_url, params: { avoir_remb: { commande_id: @avoir_remb.commande_id, montant: @avoir_remb.montant, nature: @avoir_remb.nature, type_avoir_remb: @avoir_remb.type_avoir_remb } }
    end

    assert_redirected_to avoir_remb_url(AvoirRemb.last)
  end

  test "should show avoir_remb" do
    get avoir_remb_url(@avoir_remb)
    assert_response :success
  end

  test "should get edit" do
    get edit_avoir_remb_url(@avoir_remb)
    assert_response :success
  end

  test "should update avoir_remb" do
    patch avoir_remb_url(@avoir_remb), params: { avoir_remb: { commande_id: @avoir_remb.commande_id, montant: @avoir_remb.montant, nature: @avoir_remb.nature, type_avoir_remb: @avoir_remb.type_avoir_remb } }
    assert_redirected_to avoir_remb_url(@avoir_remb)
  end

  test "should destroy avoir_remb" do
    assert_difference("AvoirRemb.count", -1) do
      delete avoir_remb_url(@avoir_remb)
    end

    assert_redirected_to avoir_rembs_url
  end
end
