# frozen_string_literal: true

class FerrumPdfTestMailer < ApplicationMailer
  def test_pdf(to:, pdf_data:, generated_at:)
    @generated_at = generated_at

    attachments["ferrum_test.pdf"] = pdf_data
    attachments.inline["logo_a1soir_2025.png"] = File.read(Rails.root.join("app/assets/images/logo_a1soir_2025.png"))

    mail(to: to, subject: "Test PDF Ferrum — A1soir") do |format|
      format.html { render template: "admin/ferrum_pdf_test_mailer/test_pdf" }
      format.text { render template: "admin/ferrum_pdf_test_mailer/test_pdf" }
    end
  end
end
