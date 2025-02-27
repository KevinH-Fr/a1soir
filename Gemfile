source "https://rubygems.org"

ruby "3.1.2"
gem "rails", "~> 7.1.3"
gem "sprockets-rails"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "redis", ">= 4.0.1"
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]
gem "bootsnap", require: false
gem "image_processing", "~> 1.2"

group :development, :test do
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ]
  gem 'rspec-rails', '~> 6.1.0'
end

group :development do
  gem "sqlite3", "~> 1.4"
  gem "web-console"
  gem "error_highlight", ">= 0.4.0", platforms: [:ruby]
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  
end

group :production do
  gem 'pg', '~> 1.4', '>= 1.4.1'
end

gem "devise", "~> 4.9"
gem 'wicked_pdf'

gem "wkhtmltopdf-binary", group: :development
gem "wkhtmltopdf-heroku", group: :production


gem "letter_opener", group: :development

gem "simple_calendar"

gem "rqrcode", "~> 2.0"

gem 'ransack'

gem 'jquery-rails'

gem 'cloudinary'
gem 'dotenv', groups: [:development, :test]

gem 'pagy'


gem 'whenever', require: false

gem 'bullet', group: 'development'

gem 'icalendar'

gem 'google-apis-calendar_v3'

gem 'stripe'