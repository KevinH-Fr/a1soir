module NavAdminHelper
  def nav_link(path, name, icon_class, options = {})
    classes = ["nav-item text-center m-2"]
    classes << "active" if current_page?(path)

    content_tag :li, class: classes do
      link_to path, options.merge({ class: "text-decoration-none" }) do
        concat content_tag(:i, "", class: "fa fa-xl brand-colored #{icon_class} m-2")
        concat content_tag(:span, name, class: "text-dark fw-bold")
      end
    end
  end
end
