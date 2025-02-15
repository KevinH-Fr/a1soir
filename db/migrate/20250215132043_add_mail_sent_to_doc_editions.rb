class AddMailSentToDocEditions < ActiveRecord::Migration[7.1]
  def change
    add_column :doc_editions, :mail_sent, :boolean
  end
end
