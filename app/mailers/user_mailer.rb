class UserMailer < ApplicationMailer
    def welcome_email
      mail(to: 'recipient@example.com', subject: 'Welcome to My App') do |format|
        format.html { render 'user_mailer/welcome_email' }
      end
    end
  end
  