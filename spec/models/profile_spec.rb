# frozen_string_literal: true

require "rails_helper"

RSpec.describe Profile, type: :model do
  describe ".commande_rapide" do
    it "finds or creates the technical profile" do
      first = Profile.commande_rapide
      second = Profile.commande_rapide

      expect(first.prenom).to eq(Profile::COMMANDE_RAPIDE_PROFILE_PRENOM)
      expect(first.nom).to be_nil
      expect(second.id).to eq(first.id)
      expect(first.commande_rapide?).to be(true)
      expect(first.hard_destroy_allowed?).to be(false)
    end
  end
end
