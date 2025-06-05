class OpenaiAssistantService
  attr_reader :thread_id

  def initialize(thread_id = nil)
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    if thread_id.present?
      @thread_id = thread_id
      #puts "♻️ Thread ID fourni réutilisé : #{@thread_id}"
    else
      @thread_id = create_thread
    end
  end

  def create_thread
    #puts "🆕 Création d’un nouveau thread OpenAI..."
    response = @client.threads.create
    thread_id = response["id"]
    #puts "🎯 Nouveau thread ID : #{thread_id}"
    thread_id
  end

  def get_messages
    return [] unless @thread_id

    response = @client.messages.list(thread_id: @thread_id)
    response["data"]
      .reverse # OpenAI renvoie du plus récent au plus ancien
      .map do |msg|
        role = msg["role"]
        text = msg["content"].map { |c| c["text"]["value"] }.join(" ")
        { role: role, text: text }
      end
  end


  def call_assistant(user_query, &block)
    #puts "💬 Envoi de message à l’assistant : #{user_query.inspect}"
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
    #puts "📡 Début du streaming pour thread : #{thread_id}"

    @client.runs.create(
      thread_id: thread_id,
      parameters: {
        assistant_id: ENV.fetch("OPENAI_ASSISTANT_ID"),
        stream: proc do |chunk, _bytesize|
          if chunk.is_a?(Hash) && chunk["object"] == "thread.message.delta"
            text = chunk.dig("delta", "content", 0, "text", "value")
            puts "🧩 Chunk reçu : #{text.inspect}" if text.present?
            block.call(text) if text && block_given?
          end
        end
      }
    )
  end
end
