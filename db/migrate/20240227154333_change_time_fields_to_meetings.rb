class ChangeTimeFieldsToMeetings < ActiveRecord::Migration[7.1]
  def change
    change_column :meetings, :datedebut, :datetime
    change_column :meetings, :datefin, :datetime
  end
end
