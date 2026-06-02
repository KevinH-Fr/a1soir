# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreOpeningHours do
  describe ".lines" do
    it "returns fallback hours when no texte exists" do
      expect(described_class.lines(texte: nil)).to eq(described_class::FALLBACK)
    end

    it "reads standard opening hours from Texte" do
      texte = Texte.create!(mode_periode_speciale: false)
      texte.horaire = "Lundi: 10:00 - 18:00\nMardi: 10:00 - 18:00"

      expect(described_class.lines(texte: texte)).to eq(
        ["Lundi: 10:00 - 18:00", "Mardi: 10:00 - 18:00"]
      )
    end

    it "uses special period hours when mode_periode_speciale is active" do
      texte = Texte.create!(mode_periode_speciale: true)
      texte.horaire = "Lundi: 10:00 - 17:00"
      texte.horaire_periode_speciale = "Tous les jours: 09:00 - 21:00"

      expect(described_class.lines(texte: texte)).to eq(["Tous les jours: 09:00 - 21:00"])
    end
  end

  describe ".for_clothing_store_schema" do
    it "returns openingHours key for schema.org" do
      texte = Texte.create!
      texte.horaire = "Samedi: 10:00 - 17:00"

      expect(described_class.for_clothing_store_schema(texte: texte)).to eq(
        "openingHours" => ["Samedi: 10:00 - 17:00"]
      )
    end
  end
end
