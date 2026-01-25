module CtaHelper
  CTA_CONFIG = {
    "collections" => {
      text: "Découvrir nos collections",
      icon: "grid-3x3-gap"
    },
    "rdv" => {
      text: "Prendre rendez-vous",
      icon: "calendar-check"
    },
    "boutique" => {
      text: "La boutique",
      icon: "shop"
    },
    "contact" => {
      text: "Nous contacter",
      icon: "envelope"
    },
    "produits" => {
      text: "Voir nos produits",
      icon: "arrow-right-circle"
    },
    "ecrire" => {
      text: "Nous écrire",
      icon: "envelope"
    },
    "appeler" => {
      text: "Nous appeler",
      icon: "telephone"
    }
  }.freeze

  def cta_button(type:, url:, variant: "light", outline: false)
    config = CTA_CONFIG[type.to_s] || raise(ArgumentError, "Type inconnu: #{type}")
    
    text = config[:text]
    icon = config[:icon]
    
    # Déterminer la classe du bouton selon le variant
    # light → bouton blanc plein (btn-light)
    # dark → bouton noir plein (btn-dark)
    # outline peut être false, true (utilise variant), ou une couleur ("light", "dark")
    if outline
      outline_color = outline == true ? variant : outline
      btn_class = "btn btn-outline-#{outline_color} btn-lg px-3 public-btn-border-radius"
    else
      btn_class = "btn btn-#{variant} btn-lg px-3 public-btn-border-radius"
    end
        
    link_to(url, class: btn_class) do
      content_tag(:i, "", class: "bi bi-#{icon} me-2") +
      content_tag(:span, text, class: "fw-bold text-uppercase small")
    end
  end
end
