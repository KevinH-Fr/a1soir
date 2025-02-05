require 'icalendar'

class MeetingIcsService
  def initialize(meetings)
    @meetings = meetings
  end

  def generate
    cal = Icalendar::Calendar.new
    cal.x_wr_calname = 'A1soir_prod_v5'

    @meetings.each do |meeting|
      cal.event do |e|
        e.dtstamp = Time.now.utc
        e.last_modified = meeting.updated_at.utc if meeting.updated_at
        e.dtstart = Icalendar::Values::DateTime.new(meeting.start_time, tzid: "Europe/Paris")
        e.dtend = Icalendar::Values::DateTime.new(meeting.end_time, tzid: "Europe/Paris")

        e.summary = meeting.full_name
        e.description = meeting.full_details || ""
        e.location = meeting.lieu || "Unknown location"
        e.uid = "a1soir-#{meeting.id}@a1soir.com"  # Unique and persistent UID
        e.sequence = meeting.updated_at.to_i if meeting.updated_at
        e.status = "CONFIRMED"  # Set the status to confirmed
      end
    end

    cal.publish
    cal.to_ical
  end
end
