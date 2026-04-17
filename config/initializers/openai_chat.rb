# frozen_string_literal: true

# OpenAI chat runtime configuration for the public chatbot.
Rails.application.config.x.openai_chat_prompt_path = Rails.root.join("config/prompts/chatbot_system.txt")
Rails.application.config.x.openai_chat_model = "gpt-4.1-mini"
Rails.application.config.x.openai_chat_store = true

default_prompt = if File.exist?(Rails.application.config.x.openai_chat_prompt_path)
                   File.read(Rails.application.config.x.openai_chat_prompt_path).strip
                 else
                   "You are a helpful assistant for Autour D'Un Soir. Keep answers concise, polite, and in the user's language."
                 end

# Source of truth: versioned repo prompt file (with safe fallback).
Rails.application.config.x.openai_chat_instructions = default_prompt
