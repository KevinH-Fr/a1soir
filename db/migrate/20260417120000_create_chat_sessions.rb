class CreateChatSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_sessions do |t|
      t.string :visitor_token, null: false
      t.string :openai_conversation_id
      t.string :last_openai_response_id
      t.text :metadata

      t.timestamps
    end

    add_index :chat_sessions, :visitor_token, unique: true
    add_index :chat_sessions, :openai_conversation_id
  end
end
