# frozen_string_literal: true

# Single source of truth for the e-shop feature flag (Stripe checkout, panier, etc.)
Rails.application.config.x.online_sales_available = ActiveModel::Type::Boolean.new.cast(
  ENV.fetch("ONLINE_SALES_AVAILABLE", "false")
)
