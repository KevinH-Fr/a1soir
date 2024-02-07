require "application_system_test_case"

class PaiementRecusTest < ApplicationSystemTestCase
  setup do
    @paiement_recu = paiement_recus(:one)
  end

  test "visiting the index" do
    visit paiement_recus_url
    assert_selector "h1", text: "Paiement recus"
  end

  test "should create paiement recu" do
    visit paiement_recus_url
    click_on "New paiement recu"

    fill_in "Commande", with: @paiement_recu.commande_id
    fill_in "Commentaires", with: @paiement_recu.commentaires
    fill_in "Montant", with: @paiement_recu.montant
    fill_in "Moyen", with: @paiement_recu.moyen
    fill_in "Typepaiement", with: @paiement_recu.typepaiement
    click_on "Create Paiement recu"

    assert_text "Paiement recu was successfully created"
    click_on "Back"
  end

  test "should update Paiement recu" do
    visit paiement_recu_url(@paiement_recu)
    click_on "Edit this paiement recu", match: :first

    fill_in "Commande", with: @paiement_recu.commande_id
    fill_in "Commentaires", with: @paiement_recu.commentaires
    fill_in "Montant", with: @paiement_recu.montant
    fill_in "Moyen", with: @paiement_recu.moyen
    fill_in "Typepaiement", with: @paiement_recu.typepaiement
    click_on "Update Paiement recu"

    assert_text "Paiement recu was successfully updated"
    click_on "Back"
  end

  test "should destroy Paiement recu" do
    visit paiement_recu_url(@paiement_recu)
    click_on "Destroy this paiement recu", match: :first

    assert_text "Paiement recu was successfully destroyed"
  end
end
