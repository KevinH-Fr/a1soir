class AddContentMailToDocEditions < ActiveRecord::Migration[7.1]
  def change
    add_column :doc_editions, :sujet, :string
    add_column :doc_editions, :destinataire, :string
    add_column :doc_editions, :message, :text
  end
end
