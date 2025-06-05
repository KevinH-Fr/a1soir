module Public
  class ChatController < ApplicationController
    include ActionController::Live

    def history
      thread_id = session[:openai_thread_id]
      if thread_id.blank?
        render json: { messages: [] }
        return
      end

      assistant = OpenaiAssistantService.new(thread_id)
      messages = assistant.get_messages

      render json: { messages: messages }
    end


    def chat
      response.headers["Content-Type"] = "text/event-stream"
      response.headers["Cache-Control"] = "no-cache"

      user_message = params[:message] || "salut"
      thread_id = session[:openai_thread_id]

     # puts "💡 Thread ID dans session (avant) : #{thread_id || 'aucun'}"

      assistant_service = OpenaiAssistantService.new(thread_id)

      session[:openai_thread_id] = assistant_service.thread_id
      # puts "✅ Thread ID utilisé : #{assistant_service.thread_id}"
      # puts "📦 Thread ID enregistré en session."

      response.headers["X-Chatbot-Thread-Id"] = assistant_service.thread_id

      begin
        assistant_service.call_assistant(user_message) do |chunk|
          response.stream.write(chunk)
        end
      rescue => e
       # puts "❌ Erreur : #{e.message}"
        response.stream.write("Error: #{e.message}")
      ensure
        response.stream.close
      end
    end
  end
end
