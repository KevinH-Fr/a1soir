class Admin::FerrumPdfTestsController < Admin::ApplicationController
  include FerrumPdfRenderable

  before_action :authenticate_admin!

  FERRUM_TEST_TEMPLATE = "admin/ferrum_pdf_tests/show"
  FERRUM_TEST_LAYOUT = "ferrum_pdf_test"

  def show
    @generated_at = Time.current

    respond_to do |format|
      format.html { render layout: FERRUM_TEST_LAYOUT }
      format.pdf do
        send_ferrum_pdf(
          template: FERRUM_TEST_TEMPLATE,
          layout: FERRUM_TEST_LAYOUT,
          filename: "ferrum_test.pdf"
        )
      end
    end
  end

  def send_test_email
    @generated_at = Time.current

    deliver_ferrum_pdf_email(template: FERRUM_TEST_TEMPLATE, layout: FERRUM_TEST_LAYOUT) do |pdf_data|
      FerrumPdfTestMailer.test_pdf(
        to: current_admin_user.email,
        pdf_data: pdf_data,
        generated_at: @generated_at
      )
    end

    redirect_to admin_root_path,
                notice: "Email test Ferrum envoyé à #{current_admin_user.email} (PDF en pièce jointe)."
  end
end
