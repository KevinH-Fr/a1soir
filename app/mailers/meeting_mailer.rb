class MeetingMailer < ApplicationMailer

  layout "mailer"

  def reminder_email(meeting)
    @meeting = meeting
    @recipient = meeting.commande&.client || meeting.client

    return unless @recipient&.mail

    ics_content = MeetingInviteIcsService.new(@meeting).generate

    attachments["meeting-#{@meeting.id}.ics"] = {
      mime_type: 'text/calendar',
      content: ics_content
    }

    I18n.with_locale(@recipient.language || :fr) do
      @subject = I18n.t('reminders.subject')

      attach_inline_logo

      mail(to: @recipient.mail, subject: @subject) do |format|
        format.html { render template: "admin/meeting_mailer/reminder_email", layout: "mailer" }
      end
    end
  end


end
