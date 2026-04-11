require "application_system_test_case"

class AvoirRembsTest < ApplicationSystemTestCase
  setup do
    @avoir_remb = avoir_rembs(:one)
  end

  test "visiting the index" do
    visit admin_avoir_rembs_url
    assert_selector "h1", text: "Avoir rembs"
  end
end
