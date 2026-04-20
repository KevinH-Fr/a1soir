# frozen_string_literal: true

# OpenAI client — global configuration for the ruby-openai gem.
OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY")
  config.log_errors = Rails.env.development?
end

# OpenAI chat runtime configuration for the public chatbot.
Rails.application.config.x.openai_chat_prompt_path = Rails.root.join("config/prompts/chatbot_system.txt")
Rails.application.config.x.openai_chat_model = "gpt-5.4-mini" #"gpt-4.1-mini"
Rails.application.config.x.openai_chat_store = true

default_prompt = if File.exist?(Rails.application.config.x.openai_chat_prompt_path)
                   File.read(Rails.application.config.x.openai_chat_prompt_path).strip
                 else
                   "You are a helpful assistant for Autour D'Un Soir. Keep answers concise, polite, and in the user's language."
                 end

# Source of truth: versioned repo prompt file (with safe fallback).
Rails.application.config.x.openai_chat_instructions = default_prompt
