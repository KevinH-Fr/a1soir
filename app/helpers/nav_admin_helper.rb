# app/helpers/navigation_helper.rb

module NavAdminHelper
    def nav_link(path, name, icon_class, options = {})
      classes = ["nav-item text-center m-2"]
      classes << "active" if current_page?(path)
      
      content_tag :li, class: classes do
        link_to path, options do
          concat content_tag(:i, "", class: icon_class)
          concat content_tag(:span, name, class: "text-dark link-plain fw-bold")
        end
      end
    end
  end
  