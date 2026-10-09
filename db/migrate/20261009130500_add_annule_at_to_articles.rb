class AddAnnuleAtToArticles < ActiveRecord::Migration[7.2]
  def change
    add_column :articles, :annule_at, :datetime
  end
end
