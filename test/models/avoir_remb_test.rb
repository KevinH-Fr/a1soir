require "test_helper"

class AvoirRembTest < ActiveSupport::TestCase
  setup do
    @commande = commandes(:one)
  end

  test "rejects blank type_avoir_remb" do
    ar = AvoirRemb.new(commande: @commande, type_avoir_remb: "", montant: 10)
    assert_not ar.valid?
    assert ar.errors.added?(:type_avoir_remb, :blank)
  end

  test "rejects unknown type_avoir_remb" do
    ar = AvoirRemb.new(commande: @commande, type_avoir_remb: "foo", montant: 10)
    assert_not ar.valid?
    assert ar.errors.added?(:type_avoir_remb, :inclusion)
  end

  test "accepts avoir or remboursement" do
    assert AvoirRemb.new(commande: @commande, type_avoir_remb: "avoir", montant: 1).valid?
    assert AvoirRemb.new(commande: @commande, type_avoir_remb: "remboursement", montant: 1).valid?
  end
end
