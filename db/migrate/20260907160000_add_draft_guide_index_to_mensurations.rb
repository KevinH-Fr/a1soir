class AddDraftGuideIndexToMensurations < ActiveRecord::Migration[7.1]
  def change
    add_column :mensurations, :draft_guide_index, :integer
  end
end
