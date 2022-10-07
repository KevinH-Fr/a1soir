require "application_system_test_case"

class PaiementsTest < ApplicationSystemTestCase
  setup do
    @paiement = paiements(:one)
  end

  test "visiting the index" do
    visit paiements_url
    assert_selector "h1", text: "Paiements"
  end

  test "should create paiement" do
    visit paiements_url
    click_on "New paiement"

    fill_in "Commande", with: @paiement.commande_id
    fill_in "Montant", with: @paiement.montant
    fill_in "Type", with: @paiement.type
    click_on "Create Paiement"

    assert_text "Paiement was successfully created"
    click_on "Back"
  end

  test "should update Paiement" do
    visit paiement_url(@paiement)
    click_on "Edit this paiement", match: :first

    fill_in "Commande", with: @paiement.commande_id
    fill_in "Montant", with: @paiement.montant
    fill_in "Type", with: @paiement.type
    click_on "Update Paiement"

    assert_text "Paiement was successfully updated"
    click_on "Back"
  end

  test "should destroy Paiement" do
    visit paiement_url(@paiement)
    click_on "Destroy this paiement", match: :first

    assert_text "Paiement was successfully destroyed"
  end
end
