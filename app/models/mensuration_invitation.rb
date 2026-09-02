class MensurationInvitation < ApplicationRecord
  # Lien public /m/:token — opaque, régénérable (regenerate_token) si l'admin renvoie l'invitation.
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
  validates :template, inclusion: { in: TEMPLATES }
  validates :locale, inclusion: { in: %w[fr en] }
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

  # Renvoi admin : nouveau lien, nouvelle échéance, l'ancien token meurt.
  def reissue!
    regenerate_token
    update!(expires_at: LINK_VALIDITY.from_now, status: mensuration.present? ? "completed" : "sent",
            otp_digest: nil, otp_sent_at: nil, otp_attempts: 0)
  end

  # Génère et stocke le code (hashé) ; retourne le code en clair pour l'e-mail uniquement.
  def generate_otp!
    code = format("%06d", SecureRandom.random_number(1_000_000))
    update!(otp_digest: BCrypt::Password.create(code), otp_sent_at: Time.current, otp_attempts: 0)
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

    if BCrypt::Password.new(otp_digest).is_password?(code.to_s.strip)
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

  private

  def set_default_expiry
    self.expires_at ||= LINK_VALIDITY.from_now
  end
end
