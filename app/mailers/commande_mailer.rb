class CommandeMailer < ApplicationMailer

    def send_email(to_email, subject, message)
        mail(to: to_email, subject: subject, body: message)
    end

    
end
