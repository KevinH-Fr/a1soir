# frozen_string_literal: true

# Inscription de comptes sur le sous-domaine admin (bouton + routes Devise).
# Fermé par défaut. Rouvrir : ADMIN_SIGNUP_ENABLED=true puis redémarrage.
# Valeurs acceptées : true/false, 1/0, yes/no, on/off.
Rails.application.config.x.admin_signup_enabled = ActiveModel::Type::Boolean.new.cast(
  ENV.fetch("ADMIN_SIGNUP_ENABLED", "false")
)
