# app/services/meeting_ics_service.rb
require 'icalendar'  # Add this line to include the Icalendar module

class MeetingIcsService
    def initialize(meetings)
      @meetings = meetings
    end
  
    def generate
      cal = Icalendar::Calendar.new
      cal.x_wr_calname = 'A1soir_new_app2'
  
      @meetings.each do |meeting|
        cal.event do |e|
          e.last_modified = Time.now.utc
  
          # Set start and end times
          e.dtstart = meeting.start_time
          e.dtend = meeting.end_time
  
          # You can adjust the time zone if needed
          # e.dtstart = Icalendar::Values::DateTime.new(meeting.start_time, tzid: "Europe/Paris")
          # e.dtend = Icalendar::Values::DateTime.new(meeting.end_time, tzid: "Europe/Paris")
  
          e.summary = meeting.full_name
          e.description = meeting.full_details
          e.location = meeting.lieu
          e.uid = "UNIQUEv2#{meeting.id}"
          e.sequence = Time.now.to_i
        end
      end
  
      cal.publish

       # Debugging: Log the calendar to check the output
        Rails.logger.debug "_________________ 
        Generated ICS:\n#{cal.to_ical}______________"

      cal.to_ical
    end
  end
  