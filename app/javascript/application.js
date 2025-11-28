// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./controllers"


import "trix"
import "@rails/actiontext"
import "./three_scene"
import "./home_text_animation"
import "./scroll_cards_carousel"
import "./discover_scroll_effect"
import "./discover_icons_animation"
import "./scroll_reveal"
import "./page_header_zoom"
import "./section_boutique_blur"

// require jquery
// require jquery_ujs

document.addEventListener("turbo:load", () => {
    AOS.init({
      // Animations se rejouent au scroll
      mirror: true,
      // Une fois l'animation terminée
      once: false,
      // Durée par défaut
      duration: 1000,
      // Désactiver les animations sur mobile si nécessaire
      disable: false,
      // Décalage par rapport au trigger point
      offset: 120,
      // Point de déclenchement (% de l'élément visible dans le viewport)
      anchorPlacement: 'top-bottom'
    });
  });
  