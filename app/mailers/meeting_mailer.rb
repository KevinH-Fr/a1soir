class MeetingMailer < ApplicationMailer

  def reminder_email(meeting)
    @meeting = meeting


      # Determine the recipient based on association
      @recipient = if meeting.commande.present?
      meeting.commande.client
    else
      meeting.client 
    end

    puts "__________recipient email: #{@recipient.mail}___________________"

    # You can customize the subject and email body as needed
    mail(to: @recipient.mail, subject: "Rappel RDV à venir#{meeting.datedebut.strftime('%H:%M')}")
  end

end
