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

    it "autorise une invitation sans template ni langue (choix après OTP)" do
      expect(build_invitation(template: nil, locale: nil)).to be_valid
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

  describe "#deliver_otp!" do
    it "génère un code et enqueue l'e-mail" do
      invitation = build_invitation.tap(&:save!)

      expect {
        expect(invitation.deliver_otp!).to be(true)
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob)

      expect(invitation.reload.otp_digest).to be_present
    end

    it "refuse un renvoi trop tôt" do
      invitation = build_invitation.tap(&:save!)
      invitation.generate_otp!

      expect {
        expect(invitation.deliver_otp!).to be(false)
      }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
    end
  end

  describe "#sync_locale!" do
    it "met à jour l'invitation et, si demandé, la fiche" do
      invitation = build_invitation(locale: "fr").tap(&:save!)
      invitation.create_mensuration!(
        template: "femme", locale: "fr", prenom: "Anna", nom: "Durand"
      )

      invitation.sync_locale!("en", persist_on_fiche: true)

      expect(invitation.reload.locale).to eq("en")
      expect(invitation.mensuration.reload.locale).to eq("en")
    end
  end

  describe "#clear_mensuration!" do
    it "détruit la fiche et repasse l'invitation en verified" do
      invitation = build_invitation.tap(&:save!)
      invitation.create_mensuration!(
        template: "femme", locale: "fr", prenom: "Anna", nom: "Durand"
      )
      invitation.update!(status: "completed")

      invitation.clear_mensuration!

      expect(invitation.reload.mensuration).to be_nil
      expect(invitation.status).to eq("verified")
    end
  end

  describe "#apply_template!" do
    it "aligne l'invitation et la fiche, et retire les mesures incompatibles" do
      invitation = build_invitation(template: "femme").tap(&:save!)
      invitation.create_mensuration!(
        template: "femme", locale: "fr", prenom: "Anna", nom: "Durand",
        measurements: { "hauteur" => "168", "taille_soutien_gorge" => "90D" }
      )

      invitation.apply_template!("homme")

      expect(invitation.reload.template).to eq("homme")
      expect(invitation.mensuration.reload.template).to eq("homme")
      expect(invitation.mensuration.value_for("hauteur")).to eq("168")
      expect(invitation.mensuration.value_for("taille_soutien_gorge")).to be_nil
    end
  end

  describe ".public_share_url" do
    it "pointe vers /mensurations sur l'hôte boutique" do
      expect(described_class.public_share_url).to include("/mensurations")
      expect(described_class.public_share_url).not_to include("/fr/m")
      expect(described_class.public_share_url).not_to match(%r{/m/})
    end
  end

  describe ".find_or_prepare_for_share!" do
    it "crée une invitation pour un nouvel e-mail" do
      invitation = described_class.find_or_prepare_for_share!(
        email: "nouveau@example.com", locale: "en", template: "homme"
      )

      expect(invitation).to be_persisted
      expect(invitation.email).to eq("nouveau@example.com")
      expect(invitation.template).to eq("homme")
      expect(invitation.locale).to eq("en")
    end

    it "reprend la même invitation et prolonge l'échéance" do
      invitation = build_invitation(template: "femme", locale: "fr").tap(&:save!)
      invitation.update!(expires_at: 1.day.ago)

      reused = described_class.find_or_prepare_for_share!(email: invitation.email)

      expect(reused.id).to eq(invitation.id)
      expect(reused).not_to be_expired
      expect(reused.template).to eq("femme")
      expect(reused.locale).to eq("fr")
    end
  end
end
