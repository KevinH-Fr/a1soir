module PagesHelper

    def nav_link_public(path, name)
        classes = ["nav-item text-center m-2"]
        classes << "active" if current_page?(path)
    
        content_tag :li, class: classes do
          link_to path, class: "text-decoration-none" do
            concat content_tag(:span, name, class: "text-dark fw-bold")
          end
        end
    end

    def card_categorie(categorie)
        content_tag :div, class: "card m-2" do
          content_tag(:div, class: "card-body") do
            concat content_tag(:h5, categorie.nom, class: "card-title")
           # concat content_tag(:p, categorie.description, class: "card-text")
           #  concat link_to "View More", categorie_path(categorie), class: "btn btn-primary"
          end
        end
      end
      

end
