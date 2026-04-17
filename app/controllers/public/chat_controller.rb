module Public
  class ChatController < ApplicationController
    include ActionController::Live

    def history
      messages = chat_service.history
      render json: { messages: messages }
    end


    def chat
      response.headers["Content-Type"] = "text/event-stream"
      response.headers["Cache-Control"] = "no-cache"
      response.headers["X-Accel-Buffering"] = "no"

      user_message = params[:message] || "salut"
      response.headers["X-Chatbot-Context-Id"] = current_chat_session.openai_conversation_id.to_s

      begin
        chat_service.call(user_message) do |chunk|
          response.stream.write(chunk)
          response.stream.flush if response.stream.respond_to?(:flush)
        end
      rescue => e
        response.stream.write("Error: #{e.message}")
      ensure
        response.stream.close
      end
    end

    private

    def chat_service
      @chat_service ||= Chatbot::GenerateReply.new(chat_session: current_chat_session)
    end

    def current_chat_session
      return @current_chat_session if defined?(@current_chat_session)

      if session[:chat_session_id].present?
        found = ChatSession.find_by(id: session[:chat_session_id])
        return @current_chat_session = found if found.present?
      end

      visitor_token = session[:chat_visitor_token].presence || SecureRandom.uuid
      session[:chat_visitor_token] = visitor_token

      chat_session = ChatSession.find_or_create_by!(visitor_token: visitor_token)

      session[:chat_session_id] = chat_session.id
      @current_chat_session = chat_session
    end
  end
end
