class GenerateQr < ApplicationService
    attr_reader :model

    def initialize(model)
        @model = model
        puts "_________________model from generate qr : #{model}"
    end

    include Rails.application.routes.url_helpers

    require "rqrcode"
    
    def call

      host = Rails.env.production? ? 'a1soir-2-2a03802389d6.herokuapp.com' : 'localhost:3000'

      qr_url = url_for(controller: model.class.name.underscore.pluralize,
            action: "show",
            id: model.id,
            only_path: false,
            host: host, #'a1soir.herokuapp.com',
            source: 'from_qr')

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

      image_name = SecureRandom.hex
      IO.binwrite("tmp/#{image_name}.png", png.to_s)
      
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open("tmp/#{image_name}.png"),
        filename: image_name,
        content_type: "png"
      )

      model.qr_code.attach(blob)
    end

end
