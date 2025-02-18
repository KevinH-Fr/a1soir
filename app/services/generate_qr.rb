class GenerateQr < ApplicationService
  attr_reader :model

  def initialize(model)
    @model = model
  end

  include Rails.application.routes.url_helpers

  require "rqrcode"
  require "stringio"
  
  def call
    host = Rails.env.production? ? 'admin.a1soir.com' : 'localhost:3000'

    # Generate the QR code URL
    qr_url = url_for(controller: "admin/#{model.class.name.underscore.pluralize}",
      action: "show",
      id: model.id,
      only_path: false,
      host: host,
      source: 'from_qr')

    # Generate the QR code image
    qrcode = RQRCode::QRCode.new(qr_url)

    png = qrcode.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: nil,
      fill: "white",
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 120
    )

    # Convert the PNG data into an IO object (in-memory)
    png_io = StringIO.new(png.to_s)
    png_io.seek(0)

    # Attach the QR code directly from memory
    model.qr_code.attach(
      io: png_io,
      filename: "qr_code_#{model.id}.png",
      content_type: "image/png"
    )
  end
end
