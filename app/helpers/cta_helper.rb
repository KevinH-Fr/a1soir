module CtaHelper
  CTA_CONFIG = {
    "collections" => {
      icon: "grid-3x3-gap"
    },
    "rdv" => {
      icon: "calendar-check"
    },
    "boutique" => {
      icon: "shop"
    },
    "contact" => {
      icon: "envelope"
    },
    "produits" => {
      icon: "arrow-right-circle"
    },
    "ecrire" => {
      icon: "envelope"
    },
    "appeler" => {
      icon: "telephone"
    }
  }.freeze

  def cta_button(type:, url:, variant: "light", outline: false)
    type_key = type.to_s
    config = CTA_CONFIG[type_key] || raise(ArgumentError, "Type inconnu: #{type}")

    text = I18n.t("public.cta.#{type_key}")
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
