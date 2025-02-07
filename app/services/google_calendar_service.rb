class GoogleCalendarService
  SCOPES = [Google::Apis::CalendarV3::AUTH_CALENDAR]

  def initialize
    @calendar_id = ENV["GMAIL_ACCOUNT"]
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = 'Google Calendar API'
    @service.authorization = authorize
  end

  # Create event and return the event ID
  def create_event_from_meeting(meeting)
    event = Google::Apis::CalendarV3::Event.new(
      summary: meeting.full_name,
      description: meeting.full_details || "",
      location: meeting.lieu || "Unknown location",
      start: { date_time: meeting.start_time.to_datetime.rfc3339 },
      end: { date_time: meeting.end_time.to_datetime.rfc3339 },
      uid: "a1soir-#{meeting.id}@a1soir.com",
      sequence: meeting.updated_at.to_i,
      status: "confirmed"
    )

    created_event = @service.insert_event(@calendar_id, event)
    created_event.id # Return the event ID
  end

  # Update existing event using the event ID
  def update_event_from_meeting(meeting)
    return unless meeting.google_calendar_event_id

    event = Google::Apis::CalendarV3::Event.new(
      summary: meeting.full_name,
      description: meeting.full_details || "",
      location: meeting.adresse_rdv || "Unknown location",
      start: { date_time: meeting.start_time.to_datetime.rfc3339 },
      end: { date_time: meeting.end_time.to_datetime.rfc3339 },
      uid: "a1soir-#{meeting.id}@a1soir.com",
      sequence: meeting.updated_at.to_i,
      status: "confirmed"
    )

    @service.update_event(@calendar_id, meeting.google_calendar_event_id, event)
  end

  # Delete event from Google Calendar using the event ID
  def delete_event(event_id)
    return unless event_id

    @service.delete_event(@calendar_id, event_id)
  end

  private

  def authorize
    credentials_json = ENV['GOOGLE_CREDENTIALS_JSON']
    raise 'GOOGLE_CREDENTIALS_JSON is not set' if credentials_json.nil? || credentials_json.empty?

    json_key_io = StringIO.new(credentials_json)
    Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: json_key_io,
      scope: SCOPES
    )
  end
end
