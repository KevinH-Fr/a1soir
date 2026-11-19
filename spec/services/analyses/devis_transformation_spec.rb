# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::DevisTransformation do
  let(:client) do
    Client.create!(
      nom: "Devis",
      prenom: "Stats",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "devis-stats-#{SecureRandom.hex(4)}@test.com"
    )
  end
  let(:profile_a) { Profile.create!(prenom: "Alice", nom: "Vente") }
  let(:profile_b) { Profile.create!(prenom: "Bob", nom: "Location") }
  let(:debut) { Time.zone.local(2026, 3, 1, 0, 0, 0) }
  let(:fin) { Time.zone.local(2026, 3, 10, 0, 0, 0) }

  def create_commande(profile:, devis:, type_locvente:, created_at:, converti_le: nil)
    commande = Commande.create!(
      client: client,
      profile: profile,
      nom: "Stats #{type_locvente}",
      montant: 10,
      devis: true,
      type_locvente: type_locvente
    )
    commande.update_columns(
      devis: devis,
      type_locvente: type_locvente,
      created_at: created_at,
      updated_at: created_at,
      converti_le: converti_le
    )
    commande
  end

  it "compte les conversions de la période et le taux de la cohorte créée" do
    create_commande(
      profile: profile_a,
      devis: true,
      type_locvente: "location",
      created_at: Time.zone.local(2026, 3, 4, 10, 0, 0)
    )
    create_commande(
      profile: profile_a,
      devis: false,
      type_locvente: "vente",
      created_at: Time.zone.local(2026, 3, 5, 10, 0, 0),
      converti_le: Time.zone.local(2026, 3, 6, 11, 0, 0)
    )
    create_commande(
      profile: profile_b,
      devis: false,
      type_locvente: "location",
      created_at: Time.zone.local(2026, 2, 2, 10, 0, 0),
      converti_le: Time.zone.local(2026, 3, 6, 12, 0, 0)
    )
    create_commande(
      profile: profile_a,
      devis: false,
      type_locvente: "mixte",
      created_at: Time.zone.local(2026, 3, 5, 15, 0, 0),
      converti_le: Time.zone.local(2026, 3, 20, 12, 0, 0)
    )
    create_commande(
      profile: profile_b,
      devis: false,
      type_locvente: "vente",
      created_at: Time.zone.local(2026, 3, 5, 16, 0, 0)
    )

    stats = described_class.call(datedebut: debut, datefin: fin)

    expect(stats[:transformes]).to eq(2)
    expect(stats[:par_type]).to eq("vente" => 1, "location" => 1, "mixte" => 0)
    expect(stats[:cohorte]).to eq(3)
    expect(stats[:cohorte_transformes]).to eq(2)
    expect(stats[:taux]).to eq(67)
    expect(stats[:by_profile][profile_a.id][:transformes]).to eq(1)
    expect(stats[:by_profile][profile_a.id][:par_type]["vente"]).to eq(1)
    expect(stats[:by_profile][profile_a.id][:cohorte]).to eq(3)
    expect(stats[:by_profile][profile_a.id][:taux]).to eq(67)
    expect(stats[:by_profile][profile_a.id][:cohorte_par_type]).to eq("vente" => 1, "location" => 0, "mixte" => 1)
    expect(stats[:by_profile][profile_b.id][:transformes]).to eq(1)
    expect(stats[:by_profile][profile_b.id][:cohorte]).to eq(0)
    expect(stats[:by_profile][profile_b.id][:taux]).to be_nil
  end

  it "limite le nombre au vendeur filtré" do
    create_commande(
      profile: profile_a,
      devis: false,
      type_locvente: "vente",
      created_at: Time.zone.local(2026, 3, 2, 10, 0, 0),
      converti_le: Time.zone.local(2026, 3, 3, 10, 0, 0)
    )
    create_commande(
      profile: profile_b,
      devis: false,
      type_locvente: "location",
      created_at: Time.zone.local(2026, 3, 2, 10, 0, 0),
      converti_le: Time.zone.local(2026, 3, 3, 10, 0, 0)
    )

    stats = described_class.call(datedebut: debut, datefin: fin, profile_id: profile_a.id)

    expect(stats[:transformes]).to eq(1)
    expect(stats[:par_type]).to eq("vente" => 1, "location" => 0, "mixte" => 0)
    expect(stats[:taux]).to eq(100)
    expect(stats[:by_profile].keys).to eq([profile_a.id])
  end
end
