# frozen_string_literal: true

# HTML (render_to_string) → PDF Ferrum → navigateur ou mailer.
module PdfRenderable
  extend ActiveSupport::Concern

  private

  def pdf_bytes(template:, layout:, pdf_options: {})
    html = render_to_string(template: template, layout: layout, formats: [:html])
    FerrumPdfFromHtml.call(html: html, pdf_options: pdf_options)
  end

  def pdf_with_header_footer(template:, layout:, header: "admin/shared/doc_entete", footer: "admin/shared/doc_footer", pdf_options: {})
    header_html = render_to_string(template: header, layout: false, formats: [:html])
    footer_html = render_to_string(template: footer, layout: false, formats: [:html])
    html = render_to_string(template: template, layout: layout, formats: [:html])
    FerrumPdfFromHtml.call(
      html: html,
      pdf_options: pdf_options.merge(
        display_header_footer: true,
        header_template: header_html,
        footer_template: footer_html,
        margin_top: 1.2,
        margin_bottom: 0.9,
        margin_left: 0.4,
        margin_right: 0.4
      )
    )
  end

  def send_pdf(template:, layout:, filename:, pdf_options: {}, disposition: "inline")
    send_data pdf_bytes(template: template, layout: layout, pdf_options: pdf_options),
              filename: filename,
              type: "application/pdf",
              disposition: disposition
  end

  def send_pdf_with_header_footer(template:, layout:, filename:, header: "admin/shared/doc_entete", footer: "admin/shared/doc_footer", pdf_options: {}, disposition: "inline")
    send_data pdf_with_header_footer(template: template, layout: layout, header: header, footer: footer, pdf_options: pdf_options),
              filename: filename,
              type: "application/pdf",
              disposition: disposition
  end

  def deliver_pdf_email(template:, layout:, pdf_options: {})
    pdf_data = pdf_bytes(template: template, layout: layout, pdf_options: pdf_options)
    yield(pdf_data).deliver_now
  end

  def deliver_pdf_with_header_footer_email(template:, layout:, header: "admin/shared/doc_entete", footer: "admin/shared/doc_footer", pdf_options: {})
    pdf_data = pdf_with_header_footer(template: template, layout: layout, header: header, footer: footer, pdf_options: pdf_options)
    yield(pdf_data).deliver_now
  end

  # Aliases rétrocompatibles (PoC Ferrum)
  alias_method :ferrum_pdf_bytes, :pdf_bytes
  alias_method :send_ferrum_pdf, :send_pdf
  alias_method :deliver_ferrum_pdf_email, :deliver_pdf_email
end

FerrumPdfRenderable = PdfRenderable
