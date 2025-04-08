class AddLabelFactureSimpleToDocEditions < ActiveRecord::Migration[7.1]
  def change
    add_column :doc_editions, :label_facture_simple, :text
  end
end
