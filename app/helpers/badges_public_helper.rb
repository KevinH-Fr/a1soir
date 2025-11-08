module BadgesPublicHelper
  # ============================================
  # BADGES PUBLIC - Helpers pour badges élégants
  # ============================================
  
  def badge_taille(produit)
    content_tag :span, class: badge_public_base_classes,
        style: badge_public_base_style do
      concat content_tag(:i, nil, class: "bi bi-rulers public-brand-color me-2")
      concat content_tag(:span, "Taille", class: "text-light opacity-75 me-1")
      concat content_tag(:span, produit.taille.nom.upcase, class: "text-light fw-bold")
    end
  end

  def badge_prix(type, montant)
    icon_class = type == "Vente" ? "bi-cash-coin" : "bi-calendar-check"
    content_tag :span, class: badge_public_base_classes,
        style: badge_public_base_style do
      concat content_tag(:i, nil, class: "bi #{icon_class} public-brand-color me-2")
      concat content_tag(:span, "#{type}", class: "text-light opacity-75 me-1")
      concat content_tag(:span, custom_currency_no_decimals_format(montant), class: "text-light fw-bold")
    end
  end

  def badge_taille_link(produit)
    link_to produit_path(slug: produit.nom.parameterize, id: produit.id),
        class: badge_public_link_classes,
        style: badge_public_link_style do
      concat content_tag(:span, produit.taille.nom, class: "fw-bold")
    end
  end

  def badge_couleur_link(produit)
    link_to produit_path(slug: produit.nom.parameterize, id: produit.id),
        class: badge_public_link_classes,
        style: badge_public_link_style do
      if produit.couleur.couleur_code.present?
        concat content_tag(:i, '', class: "bi bi-circle-fill me-2", style: "color: #{produit.couleur.couleur_code}; font-size: 0.8rem;")
      else
        concat content_tag(:i, nil, class: "bi bi-palette public-brand-color me-2")
      end
      concat content_tag(:span, produit.couleur.nom, class: "fw-bold")
    end
  end

  private

  def badge_public_base_classes
    "badge d-inline-flex align-items-center px-3 py-2"
  end

  def badge_public_base_style
    "background: linear-gradient(135deg, rgba(30, 30, 30, 0.95), rgba(15, 15, 15, 0.98)); border: 1px solid rgba(120, 120, 120, 0.4); border-radius: 0.5rem; color: #f0e4b0; font-weight: 500; transition: all 0.3s ease;"
  end

  def badge_public_link_classes
    "badge d-inline-flex align-items-center text-uppercase text-decoration-none px-3 py-2 hover-lift"
  end

  def badge_public_link_style
    "background: var(--public-brand-gradient); border: 1px solid rgba(208, 77, 123, 0.5); border-radius: 0.5rem; color: #ffffff; font-weight: 500; transition: all 0.3s ease; box-shadow: 0 2px 8px rgba(208, 77, 123, 0.3);"
  end
end

