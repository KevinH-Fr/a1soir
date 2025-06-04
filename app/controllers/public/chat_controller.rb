module Public
  class ChatController < ApplicationController
    include ActionController::Live

    def chat
      response.headers["Content-Type"] = "text/event-stream"
      response.headers["Cache-Control"] = "no-cache"

      user_message = params[:message] || "salut"
      thread_id = params[:thread_id].presence

      assistant_service = OpenaiAssistantService.new(thread_id)
      response.headers["X-Chatbot-Thread-Id"] = assistant_service.thread_id

      begin
        assistant_service.call_assistant(user_message) do |chunk|
          response.stream.write(chunk)
        end
      rescue => e
        response.stream.write("Error: #{e.message}")
      ensure
        response.stream.close
      end
    end
  end
end
