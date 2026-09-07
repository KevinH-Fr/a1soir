# frozen_string_literal: true

require "rails_helper"

RSpec.describe MensurationMailer, type: :mailer do
  let(:invitation) do
    MensurationInvitation.create!(email: "cliente@example.com", template: "femme", locale: "fr")
  end

  describe "#otp_code" do
    it "inclut le lien pour reprendre le formulaire" do
      mail = described_class.otp_code(invitation, "123456")

      form_url = invitation.public_form_url
      expect(mail.body.encoded).to include(form_url)
      expect(mail.body.encoded).to include("123456")
      expect(mail.subject).to eq(I18n.t("mensurations.mailer.otp.subject", locale: :fr))
    end
  end
end
