class UserMailer < ApplicationMailer
  def send_email
    mail(to: 'recipient@example.com', subject: 'Subject of the email')
  end
end
  