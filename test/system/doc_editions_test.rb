require "application_system_test_case"

class DocEditionsTest < ApplicationSystemTestCase
  setup do
    @doc_edition = doc_editions(:one)
  end

  test "visiting the index" do
    visit doc_editions_url
    assert_selector "h1", text: "Doc editions"
  end

  test "should create doc edition" do
    visit doc_editions_url
    click_on "New doc edition"

    fill_in "Commande", with: @doc_edition.commande_id
    fill_in "Commentaires", with: @doc_edition.commentaires
    fill_in "Doc type", with: @doc_edition.doc_type
    fill_in "Edition type", with: @doc_edition.edition_type
    click_on "Create Doc edition"

    assert_text "Doc edition was successfully created"
    click_on "Back"
  end

  test "should update Doc edition" do
    visit doc_edition_url(@doc_edition)
    click_on "Edit this doc edition", match: :first

    fill_in "Commande", with: @doc_edition.commande_id
    fill_in "Commentaires", with: @doc_edition.commentaires
    fill_in "Doc type", with: @doc_edition.doc_type
    fill_in "Edition type", with: @doc_edition.edition_type
    click_on "Update Doc edition"

    assert_text "Doc edition was successfully updated"
    click_on "Back"
  end

  test "should destroy Doc edition" do
    visit doc_edition_url(@doc_edition)
    click_on "Destroy this doc edition", match: :first

    assert_text "Doc edition was successfully destroyed"
  end
end
