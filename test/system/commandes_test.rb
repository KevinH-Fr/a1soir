require "application_system_test_case"

class CommandesTest < ApplicationSystemTestCase
  setup do
    @commande = commandes(:one)
  end

  test "visiting the index" do
    visit commandes_url
    assert_selector "h1", text: "Commandes"
  end

  test "should create commande" do
    visit commandes_url
    click_on "New commande"

    fill_in "Client", with: @commande.client_id
    fill_in "Commentaires", with: @commande.commentaires
    fill_in "Commentaires doc", with: @commande.commentaires_doc
    fill_in "Dateevent", with: @commande.dateevent
    fill_in "Debutloc", with: @commande.debutloc
    fill_in "Description", with: @commande.description
    check "Devis" if @commande.devis
    fill_in "Finloc", with: @commande.finloc
    check "Location" if @commande.location
    fill_in "Montant", with: @commande.montant
    fill_in "Nom", with: @commande.nom
    fill_in "Profile", with: @commande.profile_id
    fill_in "Statutarticles", with: @commande.statutarticles
    fill_in "Typeevent", with: @commande.typeevent
    click_on "Create Commande"

    assert_text "Commande was successfully created"
    click_on "Back"
  end

  test "should update Commande" do
    visit commande_url(@commande)
    click_on "Edit this commande", match: :first

    fill_in "Client", with: @commande.client_id
    fill_in "Commentaires", with: @commande.commentaires
    fill_in "Commentaires doc", with: @commande.commentaires_doc
    fill_in "Dateevent", with: @commande.dateevent
    fill_in "Debutloc", with: @commande.debutloc
    fill_in "Description", with: @commande.description
    check "Devis" if @commande.devis
    fill_in "Finloc", with: @commande.finloc
    check "Location" if @commande.location
    fill_in "Montant", with: @commande.montant
    fill_in "Nom", with: @commande.nom
    fill_in "Profile", with: @commande.profile_id
    fill_in "Statutarticles", with: @commande.statutarticles
    fill_in "Typeevent", with: @commande.typeevent
    click_on "Update Commande"

    assert_text "Commande was successfully updated"
    click_on "Back"
  end

  test "should destroy Commande" do
    visit commande_url(@commande)
    click_on "Destroy this commande", match: :first

    assert_text "Commande was successfully destroyed"
  end
end
