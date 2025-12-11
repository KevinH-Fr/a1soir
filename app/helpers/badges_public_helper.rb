module BadgesPublicHelper
  # ============================================
  # BADGES PUBLIC - Helpers pour badges élégants
  # ============================================
  
  def badge_taille(produit)
    content_tag :span, class: "small opacity-75" do
      concat content_tag(:span, "Taille: ", class: "me-1")
      concat content_tag(:span, produit.taille.nom.upcase, class: "")
    end
  end

  def badge_couleur(produit)
    content_tag :span, class: "small opacity-75" do
      concat content_tag(:span, "Couleur: ", class: "me-1")
      concat content_tag(:span, produit.couleur.nom, class: "")
    end
  end


  def badge_prix(type, montant)
    content_tag :span, class: "small opacity-75" do
      concat content_tag(:span, "#{type}: ", class: "me-1")
      concat content_tag(:span, custom_currency_no_decimals_format(montant), class: "")
    end
  end

  def badge_taille_link(produit)
    link_to produit.taille.nom.upcase,
            produit_path(slug: produit.nom.parameterize, id: produit.id),
            class: "btn btn-sm btn-outline-secondary"
  end

  def badge_couleur_link(produit)
    content = []
    content << content_tag(:i, '', class: "bi bi-circle-fill me-1", style: "color: #{produit.couleur.couleur_code}; font-size: 0.6rem;") if produit.couleur.couleur_code.present?
    content << produit.couleur.nom
    
    link_to safe_join(content),
            produit_path(slug: produit.nom.parameterize, id: produit.id),
            class: "btn btn-sm btn-outline-secondary"
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

