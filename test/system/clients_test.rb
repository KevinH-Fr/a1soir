require "application_system_test_case"

class ClientsTest < ApplicationSystemTestCase
  setup do
    @client = clients(:one)
  end

  test "visiting the index" do
    visit clients_url
    assert_selector "h1", text: "Clients"
  end

  test "should create client" do
    visit clients_url
    click_on "New client"

    fill_in "Adresse", with: @client.adresse
    fill_in "Commentaires", with: @client.commentaires
    fill_in "Contact", with: @client.contact
    fill_in "Cp", with: @client.cp
    fill_in "Intitule", with: @client.intitule
    fill_in "Mail", with: @client.mail
    fill_in "Mail2", with: @client.mail2
    fill_in "Nom", with: @client.nom
    fill_in "Pays", with: @client.pays
    fill_in "Prenom", with: @client.prenom
    fill_in "Propart", with: @client.propart
    fill_in "Tel", with: @client.tel
    fill_in "Tel2", with: @client.tel2
    fill_in "Ville", with: @client.ville
    click_on "Create Client"

    assert_text "Client was successfully created"
    click_on "Back"
  end

  test "should update Client" do
    visit client_url(@client)
    click_on "Edit this client", match: :first

    fill_in "Adresse", with: @client.adresse
    fill_in "Commentaires", with: @client.commentaires
    fill_in "Contact", with: @client.contact
    fill_in "Cp", with: @client.cp
    fill_in "Intitule", with: @client.intitule
    fill_in "Mail", with: @client.mail
    fill_in "Mail2", with: @client.mail2
    fill_in "Nom", with: @client.nom
    fill_in "Pays", with: @client.pays
    fill_in "Prenom", with: @client.prenom
    fill_in "Propart", with: @client.propart
    fill_in "Tel", with: @client.tel
    fill_in "Tel2", with: @client.tel2
    fill_in "Ville", with: @client.ville
    click_on "Update Client"

    assert_text "Client was successfully updated"
    click_on "Back"
  end

  test "should destroy Client" do
    visit client_url(@client)
    click_on "Destroy this client", match: :first

    assert_text "Client was successfully destroyed"
  end
end
