import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="carousel"
export default class extends Controller {
  connect() {
    // Détruire l'instance existante si elle existe (au cas où)
    const existingCarousel = bootstrap.Carousel.getInstance(this.element)
    if (existingCarousel) {
      existingCarousel.dispose()
    }

    // Calculer un délai aléatoire entre 0 et 3 secondes pour éviter que tous les carousels démarrent en même temps
    const randomDelay = Math.random() * 3000

    // Attendre le délai avant d'initialiser le carousel
    setTimeout(() => {
      // Initialiser le carousel Bootstrap
      this.carousel = new bootstrap.Carousel(this.element, {
        ride: this.element.dataset.bsRide || 'carousel',
        interval: parseInt(this.element.dataset.interval) || 5000,
        wrap: this.element.dataset.wrap !== 'false'
      })
    }, randomDelay)
  }

  disconnect() {
    // Nettoyer l'instance lors de la déconnexion (navigation Turbo)
    if (this.carousel) {
      this.carousel.dispose()
      this.carousel = null
    }
  }
}

