class MeetingMailer < ApplicationMailer

  layout "mailer"  
  
  def reminder_email(meeting)
    @meeting = meeting
    @recipient = meeting.commande&.client || meeting.client
      
    return unless @recipient&.mail
  
    I18n.locale = @recipient.language || :fr 
    @subject = I18n.t('reminders.subject')

    attachments.inline['logo_a1soir_2025.png'] = File.read(Rails.root.join('app/assets/images/logo_a1soir_2025.png'))
  
    mail(
      to: @recipient.mail,
      subject: @subject
    )
  end
  

end
