# frozen_string_literal: true

module EshopTutorialHelper
  TUTORIAL_CONFIG_PATH = Rails.root.join("config/eshop_tutorial.yml").freeze
  TUTORIAL_MODAL_ID = "eshopTutorialModal"

  def eshop_tutorial_modal_id
    TUTORIAL_MODAL_ID
  end

  def eshop_tutorial_content
    @eshop_tutorial_content ||= begin
      raw = YAML.load_file(TUTORIAL_CONFIG_PATH)
      locale_key = I18n.locale.to_s
      data = raw[locale_key].presence || raw["fr"]
      data.deep_symbolize_keys
    end
  end

  def eshop_tutorial_steps
    eshop_tutorial_content.fetch(:steps, [])
  end

  def eshop_tutorial_image_tag(step)
    image_key = step[:image].to_s
    return if image_key.blank?

    if eshop_tutorial_image_exists?(image_key)
      image_tag(
        image_key,
        class: "img-fluid rounded border shadow-sm w-100 bg-white object-fit-contain",
        alt: step[:title].to_s,
        loading: "lazy"
      )
    else
      eshop_tutorial_image_placeholder(step)
    end
  end

  def eshop_tutorial_image_exists?(image_key)
    Rails.root.join("app/assets/images", image_key).exist?
  end

  def eshop_tutorial_image_placeholder(step)
    filename = step[:image].to_s.split("/").last.presence || "capture.png"
    content_tag(:div, class: "rounded border bg-light d-flex flex-column align-items-center justify-content-center text-muted p-4 py-5") do
      safe_join([
        content_tag(:i, nil, class: "bi bi-image fs-1 mb-2", aria: { hidden: true }),
        content_tag(:span, t("admin.eshop_tutorial.image_placeholder"), class: "small text-center"),
        content_tag(:code, filename, class: "small mt-1 text-break")
      ])
    end
  end
end
