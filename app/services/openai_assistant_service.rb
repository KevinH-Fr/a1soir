class OpenaiAssistantService
  attr_reader :thread_id

  def initialize(thread_id = nil)
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    @thread_id = thread_id.presence || create_thread
  end

  def create_thread
    response = @client.threads.create
    response["id"]
  end

  def call_assistant(user_query, &block)
    @client.messages.create(
      thread_id: @thread_id,
      parameters: {
        role: "user",
        content: user_query
      }
    )

    stream_response(@thread_id, &block)
  end

  private

  def stream_response(thread_id, &block)
    @client.runs.create(
      thread_id: thread_id,
      parameters: {
        assistant_id: ENV.fetch("OPENAI_ASSISTANT_ID"),
        stream: proc do |chunk, _bytesize|
          if chunk.is_a?(Hash) && chunk["object"] == "thread.message.delta"
            text = chunk.dig("delta", "content", 0, "text", "value")
            block.call(text) if text && block_given?
          end
        end
      }
    )
  end
end
