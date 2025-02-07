class AddGoogleCalendarEventIdToMeetings < ActiveRecord::Migration[7.1]
  def change
    add_column :meetings, :google_calendar_event_id, :string
  end
end
