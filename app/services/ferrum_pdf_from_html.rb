# frozen_string_literal: true

# HTML déjà rendu (render_to_string) → PDF binaire via Ferrum.
class FerrumPdfFromHtml < ApplicationService
  DEFAULT_PDF_OPTIONS = {
    encoding: :binary,
    format: :A4,
    print_background: true
  }.freeze

  HEROKU_CHROME_FLAGS = {
    "no-sandbox" => nil,
    "disable-dev-shm-usage" => nil,
    "disable-gpu" => nil
  }.freeze

  def self.call(html:, pdf_options: {})
    new(html: html, pdf_options: pdf_options).call
  end

  def initialize(html:, pdf_options: {})
    @html = html
    @pdf_options = DEFAULT_PDF_OPTIONS.merge(pdf_options)
  end

  def call
    browser = nil
    browser = Ferrum::Browser.new(**browser_options)
    page = browser.create_page
    page.content = @html
    sleep(0.3)
    page.pdf(**@pdf_options)
  ensure
    browser&.quit
  end

  private

  def browser_options
    opts = { headless: true, timeout: 30, process_timeout: 30 }
    opts[:browser_options] = HEROKU_CHROME_FLAGS if Rails.env.production?
    opts
  end
end
