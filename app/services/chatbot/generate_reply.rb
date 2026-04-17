require "json"
require "net/http"
require "uri"

module Chatbot
  class GenerateReply
    MAX_TOOL_ITERATIONS = 5

    def initialize(chat_session:, base_url:, locale:)
      @chat_session = chat_session
      @base_url = base_url
      @locale = locale
    end

    def history
      @chat_session.chat_messages.chronological.where(role: %w[user assistant]).map do |message|
        {
          role: message.role,
          text: message.content
        }
      end
    end

    def call(user_message)
      raise ArgumentError, "user_message is required" if user_message.blank?

      ensure_conversation_id!
      persist_message!("user", user_message)

      streamed_text = +""
      initial_response = stream_create_response(
        input: user_message,
        previous_response_id: @chat_session.last_openai_response_id
      ) do |delta|
        streamed_text << delta
        yield delta if block_given?
      end

      initial_response ||= create_response(
        input: user_message,
        previous_response_id: @chat_session.last_openai_response_id
      )

      response = resolve_tool_calls(initial_response) do |delta|
        streamed_text << delta
        yield delta if block_given?
      end

      assistant_text = extract_output_text(response).to_s
      assistant_text = fallback_assistant_text if assistant_text.blank?
      initial_response_id = initial_response["id"]
      response_id = response["id"]

      if streamed_text.blank? || response_id != initial_response_id
        stream_text(assistant_text) { |chunk| yield chunk if block_given? }
      end

      persist_message!("assistant", assistant_text, openai_response_id: response["id"])
      @chat_session.update!(last_openai_response_id: response["id"])

      assistant_text
    end

    private

    def create_response(input:, previous_response_id: nil)
      parameters = base_response_parameters(input: input, previous_response_id: previous_response_id)

      client.responses.create(parameters: parameters)
    rescue StandardError
      raise if parameters[:conversation].blank?

      parameters.delete(:conversation)
      client.responses.create(parameters: parameters)
    end

    def stream_create_response(input:, previous_response_id: nil)
      return nil unless block_given?

      parameters = base_response_parameters(input: input, previous_response_id: previous_response_id)
      parameters[:stream] = true

      stream_response_http(parameters) { |delta| yield delta }
    rescue StandardError => error
      if parameters[:conversation].present?
        begin
          retry_parameters = parameters.dup
          retry_parameters.delete(:conversation)
          return stream_response_http(retry_parameters) { |delta| yield delta }
        rescue StandardError => retry_error
          Rails.logger.warn("[Chatbot::GenerateReply] Streaming retry unavailable: #{retry_error.class} - #{retry_error.message}")
        end
      end

      Rails.logger.warn("[Chatbot::GenerateReply] Streaming unavailable: #{error.class} - #{error.message}")
      nil
    end

    def resolve_tool_calls(initial_response)
      current_response = initial_response
      iterations = 0

      while iterations < MAX_TOOL_ITERATIONS
        tool_calls = extract_tool_calls(current_response)
        break if tool_calls.empty?

        tool_outputs = tool_calls.map do |call|
          result = safely_execute_tool(call)
          persist_message!(
            "tool",
            result.to_json,
            openai_response_id: current_response["id"],
            tool_name: call["name"]
          )

          {
            type: "function_call_output",
            call_id: call["call_id"],
            output: result.to_json
          }
        end

        streamed_response = stream_create_response(
          input: tool_outputs,
          previous_response_id: current_response["id"]
        ) do |delta|
          yield delta if block_given?
        end

        current_response = streamed_response || create_response(
          input: tool_outputs,
          previous_response_id: current_response["id"]
        )
        iterations += 1
      end

      if iterations >= MAX_TOOL_ITERATIONS && extract_tool_calls(current_response).any?
        persist_message!("tool", { error: "Tool loop limit reached." }.to_json)
      end

      current_response
    end

    def extract_tool_calls(response)
      Array(response["output"]).filter_map do |item|
        next unless item["type"] == "function_call"

        {
          "name" => item["name"],
          "arguments" => item["arguments"],
          "call_id" => item["call_id"]
        }
      end
    end

    def extract_output_text(response)
      return response["output_text"] if response["output_text"].present?

      message_items = Array(response["output"]).select { |item| item["type"] == "message" }
      texts = message_items.flat_map do |item|
        Array(item["content"]).filter_map do |content|
          next unless %w[output_text text].include?(content["type"])

          if content["text"].is_a?(Hash)
            content.dig("text", "value")
          else
            content["text"]
          end
        end
      end

      texts.join
    end

    def stream_text(text)
      return unless block_given?

      text.to_s.scan(/.{1,24}/m).each { |chunk| yield chunk }
    end

    def fallback_assistant_text
      "Je suis desole, je n'ai pas pu formuler de reponse pour le moment."
    end

    def safely_execute_tool(call)
      ToolDispatcher.call(
        name: call["name"],
        arguments: call["arguments"],
        base_url: @base_url,
        locale: @locale
      )
    rescue StandardError => error
      {
        error: "Tool call failed.",
        details: "#{error.class}: #{error.message}"
      }
    end

    def persist_message!(role, content, openai_response_id: nil, tool_name: nil)
      @chat_session.chat_messages.create!(
        role: role,
        content: content.to_s,
        openai_response_id: openai_response_id,
        tool_name: tool_name
      )
    end

    def ensure_conversation_id!
      return if @chat_session.openai_conversation_id.present?

      conversation_id = create_openai_conversation
      return if conversation_id.blank?

      @chat_session.update!(openai_conversation_id: conversation_id)
    end

    def create_openai_conversation
      uri = URI("https://api.openai.com/v1/conversations")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
      request["Content-Type"] = "application/json"
      request.body = {}.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)["id"]
    rescue StandardError => error
      Rails.logger.warn("[Chatbot::GenerateReply] Unable to create conversation: #{error.class} - #{error.message}")
      nil
    end

    def client
      @client ||= OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
    end

    def base_response_parameters(input:, previous_response_id:)
      parameters = {
        model: Rails.application.config.x.openai_chat_model,
        instructions: Rails.application.config.x.openai_chat_instructions,
        input: input,
        store: Rails.application.config.x.openai_chat_store,
        tools: ToolDispatcher.definitions
      }
      if @chat_session.openai_conversation_id.present?
        # OpenAI Responses rejects requests containing both conversation and previous_response_id.
        parameters[:conversation] = @chat_session.openai_conversation_id
      elsif previous_response_id.present?
        parameters[:previous_response_id] = previous_response_id
      end
      parameters
    end

    def stream_response_http(parameters)
      uri = URI("https://api.openai.com/v1/responses")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
      request["Content-Type"] = "application/json"
      request["Accept"] = "text/event-stream"
      request.body = parameters.to_json

      completed_response = nil
      buffer = +""

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 120) do |http|
        http.request(request) do |response|
          unless response.is_a?(Net::HTTPSuccess)
            error_body = response.body.to_s
            raise "Streaming request failed with status #{response.code}: #{error_body}"
          end

          response.read_body do |chunk|
            buffer << chunk
            while (separator = buffer.match(/\r?\n\r?\n/))
              event_block = buffer.slice!(0, separator.end(0))
              event_name, raw_data = parse_sse_event_block(event_block)
              next if raw_data.blank? || raw_data == "[DONE]"

              payload = JSON.parse(raw_data)
              event_type = event_name.presence || payload["type"].to_s

              case event_type
              when "response.output_text.delta"
                delta = payload["delta"].to_s
                yield delta if delta.present?
              when "response.completed"
                completed_response = payload["response"] || payload
              when "error"
                message = payload.dig("error", "message") || payload["message"] || "Unknown streaming error"
                raise "Streaming error: #{message}"
              end
            end
          end
        end
      end

      completed_response
    end

    def parse_sse_event_block(block)
      event_name = nil
      data_lines = []

      block.to_s.each_line do |line|
        stripped = line.strip
        next if stripped.blank?

        if stripped.start_with?("event:")
          event_name = stripped.split(":", 2).last.to_s.strip
        elsif stripped.start_with?("data:")
          data_lines << stripped.split(":", 2).last.to_s.lstrip
        end
      end

      [event_name, data_lines.join("\n")]
    end
  end
end
