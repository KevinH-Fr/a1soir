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

  #    laboutique_url(subdomain: "shop"),
  def card_categorie(categorie)
    link_to produits_url(subdomain: "shop", slug: categorie.nom.parameterize, id: categorie.id), class: "text-decoration-none" do
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
  
  def link_badge_taille_class(taille_id = nil)
    badge_class = "badge border brand-colored text-decoration-none"
    
    # If taille_id is nil (for "Toutes"), don't apply active class if a taille is selected
    if taille_id.nil?
      active_class = params[:taille].nil? ? "bg-brand-colored text-light" : ""
    else
      # If taille_id is not nil, apply active class when the size matches
      active_class = taille_id.to_i == params[:taille].to_i ? "bg-brand-colored text-light" : ""
    end
    
    "#{badge_class} #{active_class}"
  end
  
  def link_badge_couleur_class(couleur_id = nil)
    badge_class = "badge border brand-colored text-downcase text-decoration-none"
    
    # If taille_id is nil (for "Toutes"), don't apply active class if a taille is selected
    if couleur_id.nil?
      active_class = params[:couleur].nil? ? "bg-brand-colored text-light" : ""
    else
      # If taille_id is not nil, apply active class when the size matches
      active_class = couleur_id.to_i == params[:couleur].to_i ? "bg-brand-colored text-light" : ""
    end
    
    "#{badge_class} #{active_class}"
  end
  
  def link_badge_prix_class(prix = nil)
    badge_class = "badge border brand-colored text-downcase text-decoration-none"
    
    # If taille_id is nil (for "Toutes"), don't apply active class if a taille is selected
    if prix.nil?
      active_class = params[:prixmax].nil? ? "bg-brand-colored text-light" : ""
    else
      # If taille_id is not nil, apply active class when the size matches
      active_class = prix.to_i == params[:prixmax].to_i ? "bg-brand-colored text-light" : ""
    end
    
    "#{badge_class} #{active_class}"
  end
  
  def link_badge_categorie_class(categorie_id = nil)
    badge_class = "badge border brand-colored text-downcase text-decoration-none"
    
    # If taille_id is nil (for "Toutes"), don't apply active class if a taille is selected
    if categorie_id.nil?
      active_class = params[:id].nil? ? "bg-brand-colored text-light" : ""
    else
      # If taille_id is not nil, apply active class when the size matches
      active_class = categorie_id.to_i == params[:id].to_i ? "bg-brand-colored text-light" : ""
    end
    
    "#{badge_class} #{active_class}"
  end

  def link_badge_type_class(type = nil)
    badge_class = "badge border brand-colored text-downcase text-decoration-none"
    
    # If taille_id is nil (for "Toutes"), don't apply active class if a taille is selected
    if type.nil?
      active_class = params[:type].nil? ? "bg-brand-colored text-light" : ""
    else
      # If taille_id is not nil, apply active class when the size matches
      active_class = type == params[:type] ? "bg-brand-colored text-light" : ""
    end
    
    "#{badge_class} #{active_class}"
  end

end
