require 'icalendar'

class MeetingInviteIcsService
  def initialize(meeting)
    @meeting = meeting
  end

  def generate
    cal = Icalendar::Calendar.new
    cal.x_wr_calname = 'A1soir_prod_v5'
    cal.ip_method = "REQUEST"  # Specify request method for invites

    cal.event do |e|
      e.dtstamp = Time.now.utc
      e.last_modified = @meeting.updated_at.utc if @meeting.updated_at
      e.dtstart = Icalendar::Values::DateTime.new(@meeting.start_time, tzid: "Europe/Paris")
      e.dtend = Icalendar::Values::DateTime.new(@meeting.end_time, tzid: "Europe/Paris")

      e.summary = @meeting.nom
      e.description = @meeting.nom
      e.location = @meeting.adresse_rdv
      e.uid = "a1soir-#{@meeting.id}@a1soir.com"  # Unique and persistent UID
      e.sequence = @meeting.updated_at.to_i if @meeting.updated_at
      e.status = "CONFIRMED"  # Set the status to confirmed

      # Set the organizer
      e.organizer = Icalendar::Values::CalAddress.new("mailto:contact@a1soir.com", cn: "A1soir Organizer")

    end

    cal.publish
    cal.to_ical
  end
end
