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
    link_to categorie_path(slug: categorie.nom.parameterize, id: categorie.id), class: "text-decoration-none" do
      content_tag :div, class: "card text-bg-light mb-3" do
        image_tag(categorie.default_image, class: "card-img", style: "height: 300px; object-fit: cover;") +
        content_tag(:div, class: "card-img-overlay") do
          content_tag(:h5, categorie.nom, class: "card-title badge bg-brand-colored fs-6")
        end
      end
    end
  end

  def category_with_class(categorie)
    class_string = "text-decoration-none text-dark m-2"
    class_string += " fw-bold text-decoration-underline" if categorie == @categorie
    link_to categorie_path(slug: categorie.nom.parameterize, id: categorie.id), class: class_string do
      categorie.nom
    end
  end
  

  def card_produit(produit)
    link_to produit_path(slug: produit.nom.parameterize, id: produit.id), 
      class: "text-decoration-none", data: { turbo: false } do
      content_tag :div, class: "card text-bg-light " do
        image_tag(produit.default_image, class: "card-img", style: "max-height: 400px; object-fit: cover;") +
        content_tag(:div, class: "card-img-overlay") do
          content_tag(:h5, produit.nom, class: "card-title badge bg-brand-colored fs-6")
        end
      end
    end
  end

end
