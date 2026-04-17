class ChatSession < ApplicationRecord
  has_many :chat_messages, dependent: :destroy

  validates :visitor_token, presence: true, uniqueness: true

  def metadata_hash
    JSON.parse(metadata.presence || "{}")
  rescue JSON::ParserError
    {}
  end

  def update_metadata!(new_values)
    merged = metadata_hash.merge(new_values.stringify_keys)
    update!(metadata: merged.to_json)
  end
end
