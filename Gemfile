source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.2"
gem 'sassc-rails'
gem "rails", "~> 7.0.4"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", "~> 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "bootsnap", require: false

gem 'cloudinary'
gem "devise", "~> 4.8"
gem "rqrcode", "~> 2.1"
gem "chunky_png", "~> 1.4"
gem "ransack", "~> 3.2"
#gem 'simple_form'
#gem 'wicked_pdf'
#gem 'wkhtmltopdf-binary'
#gem 'wkhtmltopdf-binary-edge', '~> 0.12.6.0'

#gem 'wicked_pdf'
#gem "wkhtmltopdf-binary", "~> 0.12.6.5", group: :development
#gem 'wkhtmltopdf-heroku', '2.12.6.0', group: :production


gem 'wicked_pdf', '~> 2.1'
group :development do
  gem 'wkhtmltopdf-binary', '0.12.4'
end
group :production do
  gem 'wkhtmltopdf-heroku', '2.12.5.0'
end


group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
end

group :development do
  gem "web-console"
 # gem 'wkhtmltopdf-binary'
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end




group :production do
#  gem 'wkhtmltopdf-heroku'
end


