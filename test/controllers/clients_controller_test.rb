require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = clients(:one)
  end

  test "should get index" do
    get clients_url
    assert_response :success
  end

  test "should get new" do
    get new_client_url
    assert_response :success
  end

  test "should create client" do
    assert_difference("Client.count") do
      post clients_url, params: { client: { adresse: @client.adresse, commentaires: @client.commentaires, contact: @client.contact, cp: @client.cp, intitule: @client.intitule, mail: @client.mail, mail2: @client.mail2, nom: @client.nom, pays: @client.pays, prenom: @client.prenom, propart: @client.propart, tel: @client.tel, tel2: @client.tel2, ville: @client.ville } }
    end

    assert_redirected_to client_url(Client.last)
  end

  test "should show client" do
    get client_url(@client)
    assert_response :success
  end

  test "should get edit" do
    get edit_client_url(@client)
    assert_response :success
  end

  test "should update client" do
    patch client_url(@client), params: { client: { adresse: @client.adresse, commentaires: @client.commentaires, contact: @client.contact, cp: @client.cp, intitule: @client.intitule, mail: @client.mail, mail2: @client.mail2, nom: @client.nom, pays: @client.pays, prenom: @client.prenom, propart: @client.propart, tel: @client.tel, tel2: @client.tel2, ville: @client.ville } }
    assert_redirected_to client_url(@client)
  end

  test "should destroy client" do
    assert_difference("Client.count", -1) do
      delete client_url(@client)
    end

    assert_redirected_to clients_url
  end
end
