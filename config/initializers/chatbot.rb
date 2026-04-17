# frozen_string_literal: true

# Feature flag for the public OpenAI assistant widget and chat endpoints.
Rails.application.config.x.chatbot_enabled = ActiveModel::Type::Boolean.new.cast(
  ENV.fetch("CHATBOT_ENABLED", "false")
)
