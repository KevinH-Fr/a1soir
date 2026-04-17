class RemoveUserIdFromChatSessions < ActiveRecord::Migration[7.1]
  def change
    remove_reference :chat_sessions, :user, foreign_key: true, if_exists: true
  end
end
