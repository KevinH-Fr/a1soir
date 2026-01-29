import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="carousel"
export default class extends Controller {
  connect() {
    // Vérifier que l'élément est dans le DOM
    if (!document.body.contains(this.element)) {
      return
    }

    // Détruire l'instance existante si elle existe (au cas où)
    try {
      const existingCarousel = bootstrap.Carousel.getInstance(this.element)
      if (existingCarousel) {
        existingCarousel.dispose()
      }
    } catch (error) {
      // Ignorer les erreurs lors de la destruction
    }

    // Annuler le timeout précédent s'il existe
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }

    // Calculer un délai aléatoire entre 0 et 3 secondes pour éviter que tous les carousels démarrent en même temps
    const randomDelay = Math.random() * 3000

    // Attendre le délai avant d'initialiser le carousel
    this.timeoutId = setTimeout(() => {
      // Vérifier à nouveau que l'élément est toujours dans le DOM
      if (!document.body.contains(this.element)) {
        return
      }

      try {
        // Initialiser le carousel Bootstrap
        this.carousel = new bootstrap.Carousel(this.element, {
          ride: 'carousel',
          interval: parseInt(this.element.dataset.interval) || 5000,
          wrap: this.element.dataset.wrap !== 'false'
        })
      } catch (error) {
        // Ignorer les erreurs d'initialisation pour ne pas bloquer le reste
        console.warn('Erreur lors de l\'initialisation du carousel:', error)
      }
    }, randomDelay)
  }

  disconnect() {
    // Annuler le timeout si l'élément est déconnecté avant l'initialisation
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
      this.timeoutId = null
    }

    // Nettoyer l'instance lors de la déconnexion (navigation Turbo)
    if (this.carousel) {
      try {
        this.carousel.dispose()
      } catch (error) {
        // Ignorer les erreurs lors du nettoyage
      }
      this.carousel = null
    }
  }
}

