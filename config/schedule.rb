# config/schedule.rb
every 1.day, at: '6:00 pm' do
    runner "MeetingReminderJob.perform_now"
  end
  