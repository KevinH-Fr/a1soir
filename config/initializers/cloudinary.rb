
Cloudinary.config do |config|
    config.cloud_name = 'dukne3lhz'
    config.api_key = ENV['CLOUDINARY_KEY']
    config.api_secret = ENV['CLOUDINARY_SECRET']
    config.secure = true
    config.sign_url = true 
    config.type = "authenticated"
    config.cdn_subdomain = true
    config.cors_origin = ['https://a1soir-2-2a03802389d6.herokuapp.com', 'localhost:3000']

    
end
  