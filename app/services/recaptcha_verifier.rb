require 'net/http'
require 'uri'
require 'json'

class RecaptchaVerifier
  VERIFY_URL = 'https://www.google.com/recaptcha/api/siteverify'
  
  def self.verify(token, remote_ip = nil)
    return false if token.blank? || token.strip.empty?
    
    uri = URI.parse(VERIFY_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data({
      'secret' => ENV['RECAPTCHA_SECRET_KEY'],
      'response' => token,
      'remoteip' => remote_ip
    })
    
    response = http.request(request)
    result = JSON.parse(response.body)
    
    Rails.logger.info "reCAPTCHA API response: #{result.inspect}"
    
    result['success'] == true
  rescue => e
    Rails.logger.error "reCAPTCHA verification error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    false
  end
end

