# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin signup routes" do
  it "keeps registration routes off unless ADMIN_SIGNUP_ENABLED is set before boot" do
    helpers = Rails.application.routes.url_helpers

    if Rails.application.config.x.admin_signup_enabled
      expect(helpers).to respond_to(:new_admin_user_registration_path)
    else
      expect(helpers).not_to respond_to(:new_admin_user_registration_path)
      expect(helpers).to respond_to(:new_admin_user_session_path)
    end
  end
end
