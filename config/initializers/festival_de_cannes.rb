# frozen_string_literal: true

# Éléments « Festival de Cannes » (hero, navbar, etc.).
# Désactiver : FESTIVAL_DE_CANNES_ENABLED=false (ou 0, no, off)
Rails.application.config.x.festival_de_cannes_enabled = ActiveModel::Type::Boolean.new.cast(
  ENV.fetch("FESTIVAL_DE_CANNES_ENABLED", "true")
)
