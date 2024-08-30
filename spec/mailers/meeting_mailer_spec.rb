require "rails_helper"

RSpec.describe MeetingMailer, type: :mailer do
  describe "reminder_email" do
    let(:mail) { MeetingMailer.reminder_email }

    it "renders the headers" do
      expect(mail.subject).to eq("Reminder email")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
