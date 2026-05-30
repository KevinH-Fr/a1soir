# frozen_string_literal: true

require "timeout"

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

  IMAGES_LOAD_JS = <<~JS.squish
    Promise.all(
      Array.from(document.images).map(function(img) {
        if (img.complete) return Promise.resolve();
        return new Promise(function(resolve) {
          img.onload = resolve;
          img.onerror = resolve;
        });
      })
    )
  JS

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
    wait_for_document_ready!(page)
    page.pdf(**@pdf_options)
  ensure
    browser&.quit
  end

  private

  def wait_for_document_ready!(page)
    wait_timeout = image_wait_timeout

    begin
      Timeout.timeout(wait_timeout) do
        page.evaluate(IMAGES_LOAD_JS, await: true)
      end
    rescue Timeout::Error
      Rails.logger.warn("[FerrumPdfFromHtml] Image load wait timed out after #{wait_timeout}s — continuing PDF")
    end

    unless page.network.wait_for_idle(duration: 0.2, connections: 0, timeout: wait_timeout)
      Rails.logger.warn("[FerrumPdfFromHtml] network.wait_for_idle timed out after #{wait_timeout}s — continuing PDF")
    end
  end

  def image_wait_timeout
    configured = ENV.fetch("FERRUM_PDF_IMAGE_WAIT", "15").to_i
    ferrum_timeout = ENV.fetch("FERRUM_PDF_TIMEOUT", "60").to_i
    [configured, ferrum_timeout].min
  end

  def browser_options
    timeout = ENV.fetch("FERRUM_PDF_TIMEOUT", "60").to_i
    opts = { headless: true, timeout: timeout, process_timeout: timeout }
    opts[:browser_options] = HEROKU_CHROME_FLAGS if Rails.env.production?
    opts
  end
end
