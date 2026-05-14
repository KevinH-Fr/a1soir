# frozen_string_literal: true

# Bouton optionnel « Festival de Cannes » sur le hero vidéo de l’accueil.
# Désactiver : HERO_FESTIVAL_CTA_ENABLED=false (ou 0, no, off)
# ou mettre false ci-dessous à la place du cast ENV.
Rails.application.config.x.hero_festival_cta_enabled = ActiveModel::Type::Boolean.new.cast(
  ENV.fetch("HERO_FESTIVAL_CTA_ENABLED", "true")
)
