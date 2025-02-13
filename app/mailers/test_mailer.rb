class TestMailer < ApplicationMailer
    def sample_email
      mail(
        to: 'patrick.hoffman00@gmail.com',  # Replace with a real recipient address
        from: 'contact@a1soir.com',  # Must match your IONOS email
        subject: 'Test Email from Rails'
      )
    end
  end
  