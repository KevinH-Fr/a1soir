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
    link_to produits_path(slug: categorie.nom.parameterize, id: categorie.id), class: "text-decoration-none" do
      content_tag :div, class: "card text-bg-light mb-1" do
        image_tag(categorie.default_image, class: "card-img", style: "height: 300px; object-fit: cover;") +
        content_tag(:div, class: "card-img-overlay") do
          content_tag(:h5, categorie.nom, class: "card-title badge bg-brand-colored fs-6")
        end
      end
    end
  end

  def statut_disponibilite_shop(statut)
    content_tag :span, statut, class: "border p-1 rounded text-capitalize #{statut == 'disponible' ? 'text-success' : 'text-danger'}"
  end
  
  def badge_taille(produit)
    content_tag :span, "Taille : #{produit.taille.nom.upcase}", class: "border p-1 rounded"
  end
  
  def badge_prix(type, montant)
    content_tag :span, "#{type} : #{custom_currency_no_decimals_format(montant)}", class: "border p-1 rounded"
  end
  

end
