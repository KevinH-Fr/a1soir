# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public::ContactMessages", type: :request do
  let(:event_attr) { 'data-ga4-event-event-name-value="message_send"' }

  def post_message(message_attrs = {})
    post "/fr/send_contact_message", params: {
      "g-recaptcha-response" => "ok",
      contact_message: {
        prenom: "Jane",
        nom: "Doe",
        email: "contact-ga4@example.com",
        telephone: "0600000003",
        sujet: "Question",
        message: "Bonjour"
      }.merge(message_attrs)
    }
  end

  before do
    allow(RecaptchaVerifier).to receive(:verify).and_return(true)
    cookies[:analytics_consent] = "yes"
  end

  it "rend message_send une seule fois après un message enregistré" do
    expect { post_message }.to change(ContactMessage, :count).by(1)
    follow_redirect!

    expect(response.body).to include(event_attr)
    expect(response.body).not_to include("contact-ga4@example.com")

    get "/fr/contact"
    expect(response.body).not_to include(event_attr)
  end

  it "ne rend pas message_send si le message est invalide" do
    expect { post_message(message: "") }.not_to change(ContactMessage, :count)

    get "/fr/contact"
    expect(response.body).not_to include(event_attr)
  end
end
