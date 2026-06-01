# frozen_string_literal: true

module PdfHelper
  # Base64 / data URI — header/footer Chrome, QR, logo, étiquettes (petits assets).
  def pdf_image_tag(source, **options)
    src = pdf_image_src_embedded(source)
    return "" if src.blank?

    tag.img(**options.merge(src: src))
  end

  # Corps du document — vignettes produit via URL Cloudinary redimensionnée (HTML léger).
  def pdf_product_thumb_tag(source, width:, quality: "auto", **options)
    src = pdf_image_src_for_body(source, width: width, quality: quality)
    return "" if src.blank?

    tag.img(**options.merge(src: src))
  end

  def pdf_image_src_embedded(source)
    case source
    when ActiveStorage::Attached::One
      pdf_image_src_embedded(source.blob) if source.attached?
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

  def pdf_image_src_for_body(source, width:, quality: "auto")
    case source
    when ActiveStorage::Attached::One
      pdf_image_src_for_body(source.blob, width: width, quality: quality) if source.attached?
    when ActiveStorage::Blob
      pdf_cloudinary_url(source, width: width, quality: quality)
    when String
      if source.start_with?("http://", "https://", "data:")
        source
      else
        path = source.start_with?("/") ? Rails.root.join("public", source.delete_prefix("/")) : Rails.root.join(source)
        pdf_file_to_data_uri(path)
      end
    end
  end

  # Rétrocompatibilité — préférer pdf_image_src_embedded / pdf_image_src_for_body.
  alias_method :pdf_image_src, :pdf_image_src_embedded

  private

  def pdf_cloudinary_url(blob, width:, quality: "auto")
    transformation = "q_#{quality},f_auto,w_#{width}"
    "#{ApplicationHelper::CLOUDINARY_BASE_IMAGE_URL}/#{transformation}/#{blob.key}"
  end

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
