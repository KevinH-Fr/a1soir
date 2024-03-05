require "application_system_test_case"

class EnsemblesTest < ApplicationSystemTestCase
  setup do
    @ensemble = ensembles(:one)
  end

  test "visiting the index" do
    visit ensembles_url
    assert_selector "h1", text: "Ensembles"
  end

  test "should create ensemble" do
    visit ensembles_url
    click_on "New ensemble"

    click_on "Create Ensemble"

    assert_text "Ensemble was successfully created"
    click_on "Back"
  end

  test "should update Ensemble" do
    visit ensemble_url(@ensemble)
    click_on "Edit this ensemble", match: :first

    click_on "Update Ensemble"

    assert_text "Ensemble was successfully updated"
    click_on "Back"
  end

  test "should destroy Ensemble" do
    visit ensemble_url(@ensemble)
    click_on "Destroy this ensemble", match: :first

    assert_text "Ensemble was successfully destroyed"
  end
end
