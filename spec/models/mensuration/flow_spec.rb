# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mensuration::Flow do
  let(:invitation) { MensurationInvitation.create!(email: "a@example.com", template: "femme", locale: "fr") }
  let(:mensuration) { Mensuration.new(template: "femme", locale: "fr", mensuration_invitation: invitation) }

  describe "femme" do
    subject(:flow) { described_class.new(invitation, mensuration) }

    it "définit quatre écrans" do
      expect(flow.steps.map(&:key)).to eq(
        %w[identity mesures.hauteur mesures.vetements photo]
      )
    end

    it "navigue entre les étapes" do
      identity = flow.step("identity")
      hauteur = flow.step("mesures.hauteur")

      expect(flow.next(identity).key).to eq("mesures.hauteur")
      expect(flow.previous(hauteur).key).to eq("identity")
      expect(flow.position(hauteur)).to eq(2)
      expect(flow.total).to eq(4)
    end
  end

  describe "homme" do
    let(:invitation) { MensurationInvitation.create!(email: "h@example.com", template: "homme", locale: "fr") }
    let(:mensuration) { Mensuration.new(template: "homme", locale: "fr", mensuration_invitation: invitation) }
    subject(:flow) { described_class.new(invitation, mensuration) }

    it "définit les écrans tailles, corps clip et photo" do
      keys = flow.steps.map(&:key)
      expect(keys.first).to eq("identity")
      expect(keys).to include("tailles", "corps.hauteur", "corps.tour_cou", "photo")
      expect(keys.size).to eq(14)
    end
  end
end

