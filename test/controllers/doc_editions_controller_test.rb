require "test_helper"

class DocEditionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @doc_edition = doc_editions(:one)
  end

  test "should get index" do
    get doc_editions_url
    assert_response :success
  end

  test "should get new" do
    get new_doc_edition_url
    assert_response :success
  end

  test "should create doc_edition" do
    assert_difference("DocEdition.count") do
      post doc_editions_url, params: { doc_edition: { commande_id: @doc_edition.commande_id, commentaires: @doc_edition.commentaires, doc_type: @doc_edition.doc_type, edition_type: @doc_edition.edition_type } }
    end

    assert_redirected_to doc_edition_url(DocEdition.last)
  end

  test "should show doc_edition" do
    get doc_edition_url(@doc_edition)
    assert_response :success
  end

  test "should get edit" do
    get edit_doc_edition_url(@doc_edition)
    assert_response :success
  end

  test "should update doc_edition" do
    patch doc_edition_url(@doc_edition), params: { doc_edition: { commande_id: @doc_edition.commande_id, commentaires: @doc_edition.commentaires, doc_type: @doc_edition.doc_type, edition_type: @doc_edition.edition_type } }
    assert_redirected_to doc_edition_url(@doc_edition)
  end

  test "should destroy doc_edition" do
    assert_difference("DocEdition.count", -1) do
      delete doc_edition_url(@doc_edition)
    end

    assert_redirected_to doc_editions_url
  end
end
