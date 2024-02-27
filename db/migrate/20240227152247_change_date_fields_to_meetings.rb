class ChangeDateFieldsToMeetings < ActiveRecord::Migration[7.1]
  def change
    change_column :meetings, :datedebut, :time
    change_column :meetings, :datefin, :time
  end
end
