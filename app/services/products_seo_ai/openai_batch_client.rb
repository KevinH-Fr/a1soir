# frozen_string_literal: true

require "json"

module ProductsSeoAi
  class OpenaiBatchClient
    DEFAULT_MODEL = "gpt-4.1-mini"
    PROMPT_PATH = Rails.root.join("config/prompts/seo_rename_system.txt")

    def self.call(families:)
      new(families: families).call
    end

    def initialize(families:)
      @families = families
    end

    def call
      response = client.chat(parameters: chat_parameters)
      content = response.dig("choices", 0, "message", "content")
      raise "Réponse OpenAI vide" if content.blank?

      parsed = JSON.parse(content)
      items = parsed["items"] || parsed
      raise "JSON invalide : clé items manquante" unless items.is_a?(Array)

      items
    rescue JSON::ParserError => e
      raise "JSON OpenAI invalide : #{e.message}"
    end

    private

    def client
      @client ||= OpenAI::Client.new
    end

    def model
      ENV.fetch("SEO_AI_MODEL", DEFAULT_MODEL)
    end

    def system_prompt
      if File.exist?(PROMPT_PATH)
        File.read(PROMPT_PATH).strip
      else
        "Réponds uniquement en JSON {\"items\":[...]} avec handle, new_nom, approved, notes."
      end
    end

    def user_payload
      payload = @families.map do |family|
        {
          handle: family["handle"],
          old_nom: family["old_nom"],
          description: family["description"],
          variant_count: family["variant_count"],
          couleurs: family["couleurs"],
          tailles: family["tailles"],
          sample_ids: family["sample_ids"]
        }
      end

      JSON.generate({ families: payload })
    end

    def chat_parameters
      {
        model: model,
        temperature: 0.3,
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_payload }
        ],
        response_format: { type: "json_object" }
      }
    end
  end
end
