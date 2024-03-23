if Rails.env.production?
  WickedPdf.config = {
    exe_path: Gem.bin_path('wkhtmltopdf-heroku', 'wkhtmltopdf')
  }
end