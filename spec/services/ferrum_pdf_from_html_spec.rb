# frozen_string_literal: true

require "rails_helper"

RSpec.describe FerrumPdfFromHtml do
  describe ".call" do
    it "waits for images and network idle before generating the PDF" do
      page = instance_double(Ferrum::Page)
      network = instance_double(Ferrum::Network)
      browser = instance_double(Ferrum::Browser)

      allow(Ferrum::Browser).to receive(:new).and_return(browser)
      allow(browser).to receive(:create_page).and_return(page)
      allow(browser).to receive(:quit)
      allow(page).to receive(:content=)
      allow(page).to receive(:network).and_return(network)
      allow(page).to receive(:evaluate).with(described_class::IMAGES_LOAD_JS, await: true)
      allow(network).to receive(:wait_for_idle).with(duration: 0.2, connections: 0, timeout: 15).and_return(true)
      allow(page).to receive(:pdf).and_return("pdf-bytes")

      result = described_class.call(html: "<html><body></body></html>")

      expect(page).to have_received(:evaluate).with(described_class::IMAGES_LOAD_JS, await: true)
      expect(network).to have_received(:wait_for_idle).with(duration: 0.2, connections: 0, timeout: 15)
      expect(result).to eq("pdf-bytes")
    end

    it "continues PDF generation when network idle times out" do
      page = instance_double(Ferrum::Page)
      network = instance_double(Ferrum::Network)
      browser = instance_double(Ferrum::Browser)

      allow(Ferrum::Browser).to receive(:new).and_return(browser)
      allow(browser).to receive(:create_page).and_return(page)
      allow(browser).to receive(:quit)
      allow(page).to receive(:content=)
      allow(page).to receive(:network).and_return(network)
      allow(page).to receive(:evaluate).with(described_class::IMAGES_LOAD_JS, await: true)
      allow(network).to receive(:wait_for_idle).and_return(false)
      allow(page).to receive(:pdf).and_return("pdf-bytes")
      allow(Rails.logger).to receive(:warn)

      result = described_class.call(html: "<html></html>")

      expect(result).to eq("pdf-bytes")
      expect(Rails.logger).to have_received(:warn).with(/network\.wait_for_idle timed out/)
    end
  end
end
