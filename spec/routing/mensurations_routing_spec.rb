# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Routes mensurations", type: :routing do
  it "route /fr/m/:token vers le formulaire (pas vers les pages SEO)" do
    expect(get: "/fr/m/abc123XYZ").to route_to(
      controller: "public/mensurations", action: "show", locale: "fr", token: "abc123XYZ"
    )
  end

  it "route les actions OTP et sauvegarde" do
    expect(post: "/fr/m/abc123/otp").to route_to(
      controller: "public/mensurations", action: "send_otp", locale: "fr", token: "abc123"
    )
    expect(post: "/en/m/abc123/verify").to route_to(
      controller: "public/mensurations", action: "verify_otp", locale: "en", token: "abc123"
    )
    expect(delete: "/fr/m/abc123").to route_to(
      controller: "public/mensurations", action: "destroy", locale: "fr", token: "abc123"
    )
  end
end
