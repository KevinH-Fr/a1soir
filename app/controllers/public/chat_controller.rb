module Public
  class ChatController < ApplicationController
    include ActionController::Live

    def history
      messages = chat_service.history
      render json: { messages: messages }
    end


    def chat
      user_message = params[:message].to_s.strip
      return render json: { error: "Message required" }, status: :bad_request if user_message.blank?

      response.headers["Content-Type"] = "text/event-stream"
      response.headers["Cache-Control"] = "no-cache"
      response.headers["X-Accel-Buffering"] = "no"
      response.headers["X-Chatbot-Context-Id"] = current_chat_session.openai_conversation_id.to_s

      begin
        chat_service.call(user_message) do |chunk|
          response.stream.write(chunk)
          response.stream.flush if response.stream.respond_to?(:flush)
        end
      rescue => e
        Rails.logger.error("[ChatController] Streaming error: #{e.class} - #{e.message}")
        response.stream.write(I18n.t("public.chat.error_generic"))
      ensure
        response.stream.close
      end
    end

    def reset
      session_to_reset = current_chat_session
      session_to_reset.chat_messages.delete_all
      session_to_reset.update!(
        openai_conversation_id: nil,
        last_openai_response_id: nil
      )
      render json: { ok: true }
    end

    private

    def chat_service
      @chat_service ||= Chatbot::GenerateReply.new(
        chat_session: current_chat_session,
        base_url: request.base_url,
        locale: I18n.locale
      )
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
