class MeetingReminderJob < ApplicationJob
  queue_as :default

  def perform
    tomorrow_date = Time.zone.tomorrow.to_date
    meetings = Meeting.where("DATE(datedebut) = ?", tomorrow_date)

    puts "_____call meeting reminder job on #{meetings.count} meetings_____________"

    meetings.each do |meeting|
      MeetingMailer.reminder_email(meeting).deliver_now  # Use deliver_now
    end
  end
end
