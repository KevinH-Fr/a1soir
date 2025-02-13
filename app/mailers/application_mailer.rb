class ApplicationMailer < ActionMailer::Base
  default from: ENV['IONOS_USERNAME']
  layout "mailer"
end
