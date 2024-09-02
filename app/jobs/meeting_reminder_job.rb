# app/jobs/meeting_reminder_job.rb
class MeetingReminderJob < ApplicationJob
  queue_as :default

  def perform
    # Find meetings scheduled for the next day
   tomorrow = Date.tomorrow.beginning_of_day..Date.tomorrow.end_of_day
   meetings = Meeting.where(datedebut: tomorrow)

   puts "_____call meeting reminder job on #{meetings.count} meetings_____________"

    # Send reminder emails for each meeting
    meetings.each do |meeting|
      MeetingMailer.reminder_email(meeting).deliver_later
    end
  end
end
