require "application_system_test_case"

class MeetingsTest < ApplicationSystemTestCase
  setup do
    @meeting = meetings(:one)
  end

  test "visiting the index" do
    visit meetings_url
    assert_selector "h1", text: "Meetings"
  end

  test "should create meeting" do
    visit meetings_url
    click_on "New meeting"

    fill_in "Client", with: @meeting.client_id
    fill_in "Commande", with: @meeting.commande_id
    fill_in "Datedebut", with: @meeting.datedebut
    fill_in "Datefin", with: @meeting.datefin
    fill_in "Lieu", with: @meeting.lieu
    fill_in "Nom", with: @meeting.nom
    click_on "Create Meeting"

    assert_text "Meeting was successfully created"
    click_on "Back"
  end

  test "should update Meeting" do
    visit meeting_url(@meeting)
    click_on "Edit this meeting", match: :first

    fill_in "Client", with: @meeting.client_id
    fill_in "Commande", with: @meeting.commande_id
    fill_in "Datedebut", with: @meeting.datedebut
    fill_in "Datefin", with: @meeting.datefin
    fill_in "Lieu", with: @meeting.lieu
    fill_in "Nom", with: @meeting.nom
    click_on "Update Meeting"

    assert_text "Meeting was successfully updated"
    click_on "Back"
  end

  test "should destroy Meeting" do
    visit meeting_url(@meeting)
    click_on "Destroy this meeting", match: :first

    assert_text "Meeting was successfully destroyed"
  end
end
