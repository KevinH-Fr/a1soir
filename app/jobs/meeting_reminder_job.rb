# app/jobs/meeting_reminder_job.rb
class MeetingReminderJob < ApplicationJob
  queue_as :default

  def perform
    # Ensure tomorrow's date is interpreted in UTC
    tomorrow_date = Time.zone.tomorrow.to_date
  
    # Convert datedebut to UTC before comparing
    meetings = Meeting.where("DATE(datedebut) = ?", tomorrow_date)
  
   # puts "_____call meeting reminder job on #{meetings.count} meetings_____________"
  
    # Send reminder emails for each meeting
    meetings.each do |meeting|
      MeetingMailer.reminder_email(meeting).deliver_later
    end
  end
  
  
end
