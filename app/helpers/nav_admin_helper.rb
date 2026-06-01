module NavAdminHelper
  # Highlight when +controller_path+ matches (+nav_controller+ can be a String or Array).
  # +nav_action+ (optional) limits active to one action — needed when several routes share a controller.
  def nav_link(path, name, icon_class, nav_controller:, nav_action: nil, **html_options)
    active = Array(nav_controller).include?(controller_path)
    active &&= (action_name == nav_action.to_s) if nav_action.present?

    extra_class = html_options.delete(:class)
    link_classes = %w[
      nav-link d-inline-flex align-items-center justify-content-start justify-content-xxl-center
      gap-2 rounded-3 px-3 py-2 text-decoration-none w-100 w-xxl-auto
    ]
    link_classes << "active" if active
    link_classes << extra_class if extra_class.present?

    opts = html_options.merge(class: link_classes.join(" "))
    opts[:aria] = (opts[:aria] || {}).merge(current: "page") if active

    content_tag :li, class: "nav-item text-start text-xxl-center" do
      link_to path, opts do
        safe_join([
          tag.i(class: "bi #{icon_class} fs-5 lh-1 flex-shrink-0", aria: { hidden: true }),
          tag.span(name, class: "nav-admin-link-label")
        ])
      end
    end
  end
end
