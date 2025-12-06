import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "image"]

  connect() {
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.handleScroll, { passive: true })
    this.handleScroll() // Initial call
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
  }

  handleScroll() {
    const windowHeight = window.innerHeight
    const viewportCenter = windowHeight / 2
    
    // Synchroniser les textes avec les images
    this.textTargets.forEach((textWrapper, index) => {
      const imageWrapper = this.imageTargets[index]
      if (!imageWrapper) return
      
      // Calculer la position de l'image dans le viewport
      const imageRect = imageWrapper.getBoundingClientRect()
      const imageCenter = imageRect.top + (imageRect.height / 2)
      const distanceFromCenter = Math.abs(imageCenter - viewportCenter)
      
      // Zone de visibilité : plus large pour une transition douce
      const maxDistance = windowHeight * 0.6
      
      if (distanceFromCenter < maxDistance && imageRect.top < windowHeight && imageRect.bottom > 0) {
        // Calculer l'opacité avec une courbe douce
        const visibility = 1 - (distanceFromCenter / maxDistance)
        const opacity = Math.pow(visibility, 1.5) // Courbe plus douce
        
        textWrapper.style.opacity = opacity
        textWrapper.style.display = opacity > 0.1 ? 'block' : 'none'
        
        // Ajouter un léger effet de translation pour plus d'élégance
        const translateY = (1 - visibility) * 20 // Descend légèrement quand on s'éloigne du centre
        textWrapper.style.transform = `translateY(calc(-50% + ${translateY}px))`
      } else {
        // Image hors de la zone : cacher le texte
        textWrapper.style.opacity = '0'
        textWrapper.style.display = 'none'
      }
    })
  }
}
