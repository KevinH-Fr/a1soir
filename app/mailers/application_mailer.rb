class ApplicationMailer < ActionMailer::Base
  default from: ENV['IONOS_USERNAME']
  layout "mailer"

  LOGO_FILENAME = "logo_a1soir_2025.png"

  private

  def attach_inline_logo
    logo_path = Rails.root.join("app/assets/images/#{LOGO_FILENAME}")
    attachments.inline[LOGO_FILENAME] = File.read(logo_path) if File.exist?(logo_path)
  end
end
