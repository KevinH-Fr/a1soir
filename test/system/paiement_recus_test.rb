require "application_system_test_case"

class PaiementRecusTest < ApplicationSystemTestCase
  setup do
    @paiement_recu = paiement_recus(:one)
  end

  test "visiting the index" do
    visit admin_paiement_recus_url
    assert_selector "h1", text: "Paiement recus"
  end
end
