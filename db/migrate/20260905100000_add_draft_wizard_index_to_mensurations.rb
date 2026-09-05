class AddDraftWizardIndexToMensurations < ActiveRecord::Migration[7.2]
  def change
    add_column :mensurations, :draft_wizard_index, :integer
  end
end
