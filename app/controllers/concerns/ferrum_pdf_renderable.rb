# frozen_string_literal: true

# HTML (render_to_string) → PDF Ferrum → navigateur ou mailer.
# Inclure dans les contrôleurs admin qui génèrent un PDF Ferrum (ex. FerrumPdfTestsController).
module FerrumPdfRenderable
  extend ActiveSupport::Concern

  private

  def ferrum_pdf_bytes(template:, layout:, pdf_options: {})
    html = render_to_string(template: template, layout: layout, formats: [:html])
    FerrumPdfFromHtml.call(html: html, pdf_options: pdf_options)
  end

  def send_ferrum_pdf(template:, layout:, filename:, pdf_options: {}, disposition: "inline")
    send_data ferrum_pdf_bytes(template: template, layout: layout, pdf_options: pdf_options),
              filename: filename,
              type: "application/pdf",
              disposition: disposition
  end

  # Ex. deliver_ferrum_pdf_email(template: "...", layout: "pdf") { |pdf_data| CommandeMailer.email_commande(@doc_edition, pdf_data) }
  def deliver_ferrum_pdf_email(template:, layout:, pdf_options: {})
    pdf_data = ferrum_pdf_bytes(template: template, layout: layout, pdf_options: pdf_options)
    yield(pdf_data).deliver_now
  end
end
