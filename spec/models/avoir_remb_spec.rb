# frozen_string_literal: true

require "rails_helper"

RSpec.describe AvoirRemb, type: :model do
  let(:client) do
    Client.create!(
      nom: "Remb",
      prenom: "Moyen",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "remb-moyen-#{SecureRandom.hex(4)}@test.com"
    )
  end
  let(:profile) { Profile.create!(prenom: "R", nom: "M") }

  def boutique_commande
    Commande.create!(
      client: client,
      profile: profile,
      nom: "Boutique remb",
      montant: 100,
      devis: false,
      type_locvente: "vente",
      eshop: false
    )
  end

  def eshop_commande
    Commande.create!(
      client: client,
      profile: profile,
      nom: "Eshop remb",
      montant: 100,
      devis: false,
      type_locvente: "vente",
      eshop: true
    )
  end

  it "requires moyen on create for boutique remboursements" do
    remb = AvoirRemb.new(
      commande: boutique_commande,
      type_avoir_remb: "remboursement",
      montant: 10
    )
    expect(remb).not_to be_valid
    expect(remb.errors[:moyen]).to be_present
  end

  it "accepts a new boutique remboursement with a known moyen" do
    remb = AvoirRemb.new(
      commande: boutique_commande,
      type_avoir_remb: "remboursement",
      montant: 10,
      moyen: "espèces"
    )
    expect(remb).to be_valid
  end

  it "keeps an existing boutique remboursement without moyen valid on update" do
    remb = AvoirRemb.new(
      commande: boutique_commande,
      type_avoir_remb: "remboursement",
      montant: 10,
      moyen: "espèces"
    )
    remb.save!
    remb.update_columns(moyen: nil)

    remb.montant = 15
    expect(remb).to be_valid
    expect(remb.save).to be(true)
    expect(remb.reload.moyen).to be_nil
  end

  it "clears moyen when type is avoir" do
    remb = AvoirRemb.create!(
      commande: boutique_commande,
      type_avoir_remb: "avoir",
      montant: 10,
      moyen: "carte bleue"
    )
    expect(remb.moyen).to be_nil
  end

  it "allows eshop remboursements without moyen" do
    remb = AvoirRemb.new(
      commande: eshop_commande,
      type_avoir_remb: "remboursement",
      montant: 10
    )
    expect(remb).to be_valid
  end
end
