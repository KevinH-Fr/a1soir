class CreateChatMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_messages do |t|
      t.references :chat_session, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
      t.string :openai_response_id
      t.string :tool_name
      t.text :metadata

      t.timestamps
    end

    add_index :chat_messages, [:chat_session_id, :created_at]
    add_index :chat_messages, :openai_response_id
  end
end
