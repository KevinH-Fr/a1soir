require "application_system_test_case"

class AvoirRembsTest < ApplicationSystemTestCase
  setup do
    @avoir_remb = avoir_rembs(:one)
  end

  test "visiting the index" do
    visit avoir_rembs_url
    assert_selector "h1", text: "Avoir rembs"
  end

  test "should create avoir remb" do
    visit avoir_rembs_url
    click_on "New avoir remb"

    fill_in "Commande", with: @avoir_remb.commande_id
    fill_in "Montant", with: @avoir_remb.montant
    fill_in "Nature", with: @avoir_remb.nature
    fill_in "Type avoir remb", with: @avoir_remb.type_avoir_remb
    click_on "Create Avoir remb"

    assert_text "Avoir remb was successfully created"
    click_on "Back"
  end

  test "should update Avoir remb" do
    visit avoir_remb_url(@avoir_remb)
    click_on "Edit this avoir remb", match: :first

    fill_in "Commande", with: @avoir_remb.commande_id
    fill_in "Montant", with: @avoir_remb.montant
    fill_in "Nature", with: @avoir_remb.nature
    fill_in "Type avoir remb", with: @avoir_remb.type_avoir_remb
    click_on "Update Avoir remb"

    assert_text "Avoir remb was successfully updated"
    click_on "Back"
  end

  test "should destroy Avoir remb" do
    visit avoir_remb_url(@avoir_remb)
    click_on "Destroy this avoir remb", match: :first

    assert_text "Avoir remb was successfully destroyed"
  end
end
