require "test_helper"

class PdfGeneratorControllerTest < ActionDispatch::IntegrationTest
  test "should get generate_pdf" do
    get pdf_generator_generate_pdf_url
    assert_response :success
  end
end
