# frozen_string_literal: true

module Chatbot
  def self.enabled?
    Rails.application.config.x.chatbot_enabled
  end
end
