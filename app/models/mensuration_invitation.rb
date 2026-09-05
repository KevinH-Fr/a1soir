require "bcrypt"

class MensurationInvitation < ApplicationRecord
  # Token interne /m/:token (session OTP). Le lien à partager est /mensurations.
  has_secure_token :token

  # Même forme qu'en base pour les recherches (aligné sur Client.normalizes :mail).
  normalizes :email, with: ->(email) { email.to_s.strip.downcase.presence }

  belongs_to :client, optional: true
  has_one :mensuration, dependent: :destroy

  TEMPLATES = %w[femme homme].freeze
  STATUSES = %w[sent verified completed expired].freeze

  LINK_VALIDITY = 7.days
  OTP_VALIDITY = 15.minutes
  OTP_MAX_ATTEMPTS = 5
  # Anti-spam : délai minimum entre deux envois de code.
  OTP_RESEND_INTERVAL = 60.seconds

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :template, inclusion: { in: TEMPLATES }, allow_nil: true
  validates :locale, inclusion: { in: %w[fr en] }, allow_nil: true
  validates :status, inclusion: { in: STATUSES }

  before_validation :set_default_expiry, on: :create

  def self.ransackable_attributes(_auth_object = nil)
    %w[email nom prenom status template locale created_at expires_at]
  end

  # La recherche admin ne porte que sur des attributs, aucune association exposée.
  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def expired?
    expires_at.past?
  end

  def usable?
    !expired?
  end

  def preferences_chosen?
    locale.present? && template.present?
  end

  def completed?
    status == "completed"
  end

  # Lien public unique (admin « Copier ») : hôte boutique, pas le sous-domaine admin.
  def self.public_share_url
    Rails.application.routes.url_helpers.mensuration_gate_url(
      **public_form_url_options
    )
  end

  # Reprise sur le même e-mail : on prolonge l'échéance, on ne crée pas de doublon.
  def self.find_or_prepare_for_share!(email:, locale: nil, template: nil)
    invitation = where(email: email).order(created_at: :desc, id: :desc).first
    if invitation
      invitation.prepare_for_share_start!(locale: locale, template: template)
      invitation
    else
      create!(email: email, locale: locale, template: template)
    end
  end

  # Invitation + fiche dans la même transaction (évite un genre divergent).
  def apply_template!(template)
    transaction do
      update!(template: template)
      mensuration&.apply_template!(template)
    end
  end

  def sync_locale!(loc, persist_on_fiche: false)
    loc = loc.to_s.presence_in(%w[fr en])
    return if loc.blank? || locale == loc

    transaction do
      update!(locale: loc)
      mensuration&.update!(locale: loc) if persist_on_fiche
    end
  end

  def build_public_mensuration
    build_mensuration(
      template: template.presence || TEMPLATES.first,
      locale: locale.presence || "fr",
      prenom: prenom,
      nom: nom
    )
  end

  def deliver_otp!
    return false unless otp_resend_allowed?

    code = generate_otp!
    MensurationMailer.otp_code(self, code).deliver_later
    true
  end

  def clear_mensuration!
    transaction do
      mensuration&.destroy
      update!(status: "verified")
    end
  end

  def prepare_for_share_start!(locale:, template:)
    attrs = { expires_at: LINK_VALIDITY.from_now }
    attrs[:locale] = locale if locale.present?
    attrs[:template] = template if template.present?
    update!(attrs)
  end

  # Génère et stocke le code (hashé) ; retourne le code en clair pour l'e-mail uniquement.
  def generate_otp!
    code = format("%06d", SecureRandom.random_number(1_000_000))
    update!(otp_digest: ::BCrypt::Password.create(code), otp_sent_at: Time.current, otp_attempts: 0)
    code
  end

  def otp_resend_allowed?
    otp_sent_at.nil? || otp_sent_at < OTP_RESEND_INTERVAL.ago
  end

  # Vérifie le code : expiration courte + compteur d'essais pour bloquer la force brute.
  def verify_otp(code)
    return false if otp_digest.blank? || otp_sent_at.blank?
    return false if otp_sent_at < OTP_VALIDITY.ago
    return false if otp_attempts >= OTP_MAX_ATTEMPTS

    if ::BCrypt::Password.new(otp_digest).is_password?(code.to_s.strip)
      # Code à usage unique : consommé dès le succès.
      update!(otp_digest: nil, otp_attempts: 0, status: mensuration.present? ? status : "verified")
      true
    else
      increment!(:otp_attempts)
      false
    end
  end

  def full_name
    [prenom, nom].compact_blank.join(" ").presence
  end

  def self.public_form_url_options
    if Rails.env.production?
      { host: ENV.fetch("PUBLIC_APP_HOST", "a1soir.com"), protocol: "https" }
    else
      { host: ENV.fetch("PUBLIC_APP_HOST", "localhost"), port: 3000, protocol: "http" }
    end
  end

  private

  def set_default_expiry
    self.expires_at ||= LINK_VALIDITY.from_now
  end
end
