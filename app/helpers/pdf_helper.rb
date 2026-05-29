# frozen_string_literal: true

module PdfHelper
  def pdf_image_tag(source, **options)
    src = pdf_image_src(source)
    return "" if src.blank?

    tag.img(**options.merge(src: src))
  end

  def pdf_image_src(source)
    case source
    when ActiveStorage::Attached::One
      pdf_image_src(source.blob) if source.attached?
    when ActiveStorage::Blob
      pdf_blob_to_data_uri(source)
    when String
      if source.start_with?("http://", "https://", "data:")
        source
      else
        path = source.start_with?("/") ? Rails.root.join("public", source.delete_prefix("/")) : Rails.root.join(source)
        pdf_file_to_data_uri(path)
      end
    end
  end

  private

  def pdf_file_to_data_uri(path)
    return unless path.exist?

    mime = Marcel::MimeType.for(path, name: path.basename.to_s)
    data = Base64.strict_encode64(path.read)
    "data:#{mime};base64,#{data}"
  end

  def pdf_blob_to_data_uri(blob)
    mime = blob.content_type.presence || "application/octet-stream"
    data = Base64.strict_encode64(blob.download)
    "data:#{mime};base64,#{data}"
  end
end
