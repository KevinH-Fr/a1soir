class ChatMessage < ApplicationRecord
  belongs_to :chat_session

  validates :role, presence: true
  validates :content, presence: true

  scope :chronological, -> { order(:created_at, :id) }
end
