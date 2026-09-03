# frozen_string_literal: true

require "rails_helper"

RSpec.describe MensurationInvitation, type: :model do
  def build_invitation(attrs = {})
    described_class.new({ email: "cliente@example.com", template: "femme", locale: "fr" }.merge(attrs))
  end

  describe "création" do
    it "génère et persiste un token unique en base" do
      invitation = build_invitation
      invitation.save!

      expect(invitation.token).to be_present
      expect(described_class.find_by(token: invitation.token)).to eq(invitation)
    end

    it "expire par défaut à +7 jours" do
      invitation = build_invitation
      invitation.save!

      expect(invitation.expires_at).to be_within(1.minute).of(7.days.from_now)
      expect(invitation).not_to be_expired
    end

    it "normalise l'email" do
      invitation = build_invitation(email: "  Cliente@Example.COM ")
      invitation.save!

      expect(invitation.email).to eq("cliente@example.com")
    end

    it "refuse un template inconnu" do
      expect(build_invitation(template: "enfant")).not_to be_valid
    end

    it "exige un template homme ou femme" do
      expect(build_invitation(template: nil)).not_to be_valid
      expect(build_invitation(template: "")).not_to be_valid
    end
  end

  describe "OTP" do
    let(:invitation) { build_invitation.tap(&:save!) }

    it "stocke uniquement un hash BCrypt, jamais le code en clair" do
      code = invitation.generate_otp!

      expect(invitation.otp_digest).to be_present
      expect(invitation.otp_digest).not_to include(code)
      expect(BCrypt::Password.new(invitation.otp_digest).is_password?(code)).to be(true)
    end

    it "valide le bon code et le consomme (usage unique)" do
      code = invitation.generate_otp!

      expect(invitation.verify_otp(code)).to be(true)
      expect(invitation.reload.otp_digest).to be_nil
      expect(invitation.verify_otp(code)).to be(false)
    end

    it "refuse un mauvais code et incrémente les essais" do
      invitation.generate_otp!

      expect(invitation.verify_otp("000000")).to be(false)
      expect(invitation.reload.otp_attempts).to eq(1)
    end

    it "bloque après le nombre maximal d'essais" do
      code = invitation.generate_otp!
      MensurationInvitation::OTP_MAX_ATTEMPTS.times { invitation.verify_otp("000000") }

      expect(invitation.verify_otp(code)).to be(false)
    end

    it "refuse un code expiré" do
      code = invitation.generate_otp!
      invitation.update!(otp_sent_at: 16.minutes.ago)

      expect(invitation.verify_otp(code)).to be(false)
    end

    it "limite la fréquence d'envoi" do
      invitation.generate_otp!
      expect(invitation.otp_resend_allowed?).to be(false)

      invitation.update!(otp_sent_at: 2.minutes.ago)
      expect(invitation.otp_resend_allowed?).to be(true)
    end
  end

  describe "#reissue!" do
    it "invalide l'ancien token et repousse l'échéance" do
      invitation = build_invitation.tap(&:save!)
      invitation.update!(expires_at: 1.day.ago)
      old_token = invitation.token

      invitation.reissue!

      expect(invitation.token).not_to eq(old_token)
      expect(invitation).not_to be_expired
    end
  end
end
