// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./controllers"


import "trix"
import "@rails/actiontext"
import "./scroll_reveal"

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
  