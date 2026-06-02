# frozen_string_literal: true

module SeoPagesHelper
  include PagesHelper
  def seo_page_i18n_key(page)
    SeoPages::Registry.i18n_key(page)
  end

  def seo_page_t(page, key, **options)
    I18n.t("public.seo_pages.#{seo_page_i18n_key(page)}.#{key}", **options)
  end

  def seo_page_path_for(page)
    return festival_de_cannes_path if page[:scope] == "redirect"

    if page[:scope] == "guides"
      seo_guide_path(slug: page[:slug])
    else
      seo_page_path(slug: page[:slug])
    end
  end

  def seo_page_label(page)
    return t("public.footer.festival_de_cannes") if page[:scope] == "redirect"

    seo_page_t(page, :link_title, default: seo_page_t(page, :header_title))
  end

  def seo_page_includes?(page, feature)
    Array(page[:includes]).include?(feature.to_s)
  end

  def seo_page_breadcrumbs(page)
    crumbs = [
      { name: structured_breadcrumb_name(:home), url: root_url },
      { name: I18n.t("public.seo_pages.hub.title"), url: seo_guides_hub_url }
    ]

    if page[:scope] == "guides"
      crumbs << {
        name: I18n.t("public.seo_pages.hub.groups.#{page[:hub_group]}"),
        url: "#{seo_guides_hub_url}##{page[:hub_group]}"
      }
    end

    crumbs << { name: seo_page_t(page, :header_title), url: public_page_url }
    crumbs
  end

  def seo_page_section_keys(page)
    sections = I18n.t("public.seo_pages.#{seo_page_i18n_key(page)}.sections", default: {})
    sections.is_a?(Hash) ? sections.keys.map(&:to_s) : []
  end

  def seo_page_section_image(page, section_key)
    resolved_images(page)[section_key.to_s]
  end

  def seo_page_image_source(image)
    collection_card_image_source(image)
  end

  def seo_page_og_image_url(page)
    image = resolved_images(page).values.find { |section| section[:image].present? }&.dig(:image)
    return nil if image.blank?

    absolute_image_url(image)
  end

  def absolute_image_url(image)
    if image.is_a?(ActiveStorage::Attached::One) && image.attached?
      return url_for(image)
    end

    path = image_path_helper(image)
    return path if path.blank?
    return path if path.start_with?("http://", "https://")

    "#{root_url.chomp('/')}#{path}"
  end

  def resolved_images(page)
    @resolved_seo_page_images ||= {}
    cache_key = [page[:scope], page[:slug], I18n.locale].join("/")
    @resolved_seo_page_images[cache_key] ||= SeoPages::CategoryImages.call(
      page,
      section_keys: seo_page_section_keys(page)
    )
  end

  def seo_page_html(html)
    return "" if html.blank?

    fragment = Nokogiri::HTML::DocumentFragment.parse(html.to_s)
    fragment.css("a").each do |anchor|
      classes = anchor["class"].to_s.split
      classes << "seo-page-link" unless classes.include?("seo-page-link")
      anchor["class"] = classes.join(" ")
    end
    fragment.to_html.html_safe
  end

  def seo_page_faq_items(page)
    faq = I18n.t("public.seo_pages.#{seo_page_i18n_key(page)}.faq", default: {})
    return [] unless faq.is_a?(Hash)

    faq.keys.sort_by { |k| k.to_s }.filter_map do |key|
      item = faq[key]
      next unless item.is_a?(Hash) && item[:question].present?

      { id: key.to_s, question: item[:question], answer_html: item[:answer_html] }
    end
  end

  def seo_page_faq_schema(page)
    entities = seo_page_faq_items(page).filter_map do |item|
      answer_text = ActionController::Base.helpers.strip_tags(item[:answer_html].to_s).squish
      next if answer_text.blank?

      {
        "@type" => "Question",
        "name" => item[:question],
        "acceptedAnswer" => {
          "@type" => "Answer",
          "text" => answer_text
        }
      }
    end

    return nil if entities.empty?

    {
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => entities
    }
  end

  def seo_page_products_collection_url(page)
    categories = seo_page_categories(page)
    produits_filter_url(
      category_names: categories.map(&:nom),
      search: SeoPages::ProductKeywords.call(page).first.presence
    )
  end

  def seo_page_categories(page)
    SeoPages::CategoryScope.call(page)
  end

  def seo_page_category_url(category)
    produits_filter_url(category_names: category.nom)
  end

  SEO_HUB_GROUP_ORDER = %w[local guides events services].freeze

  SEO_HUB_GROUP_ICONS = {
    "local" => "geo-alt-fill",
    "guides" => "book-half",
    "events" => "stars",
    "services" => "bag-heart"
  }.freeze

  def seo_hub_groups_sorted(pages_by_group)
    ordered = SEO_HUB_GROUP_ORDER.filter_map do |group|
      pages = pages_by_group[group]
      [group, pages] if pages.present?
    end

    extra = pages_by_group.except(*SEO_HUB_GROUP_ORDER).to_a
    ordered + extra
  end

  def seo_hub_group_icon(group)
    SEO_HUB_GROUP_ICONS.fetch(group.to_s, "arrow-right")
  end
end
