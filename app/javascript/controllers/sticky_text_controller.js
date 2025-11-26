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
    const section = this.element
    const rect = section.getBoundingClientRect()
    const windowHeight = window.innerHeight
    const sectionTop = section.offsetTop
    const sectionHeight = section.offsetHeight
    const currentScroll = window.scrollY
    
    // Calculer la progression du scroll dans la section (0 à 1)
    let progress = 0
    if (rect.top <= 0 && rect.bottom > 0) {
      const scrollStart = sectionTop
      const scrollEnd = sectionTop + sectionHeight - windowHeight
      
      if (currentScroll >= scrollStart && currentScroll <= scrollEnd) {
        progress = (currentScroll - scrollStart) / (scrollEnd - scrollStart)
        progress = Math.max(0, Math.min(1, progress))
      } else if (currentScroll < scrollStart) {
        progress = 0
      } else {
        progress = 1
      }
    }
    
    const numTexts = this.textTargets.length
    const numImages = this.imageTargets.length
    
    // Synchroniser les textes avec les images
    let activeIndex = -1
    let maxVisibility = 0
    
    this.textTargets.forEach((textWrapper, index) => {
      const imageWrapper = this.imageTargets[index]
      
      if (!imageWrapper) return
      
      // Calculer la position de l'image dans le viewport
      const imageRect = imageWrapper.getBoundingClientRect()
      const imageTop = imageRect.top
      const imageBottom = imageRect.bottom
      const imageHeight = imageRect.height
      
      // Le texte apparaît quand l'image est centrée dans le viewport
      const imageCenter = imageTop + (imageHeight / 2)
      const viewportCenter = windowHeight / 2
      const distanceFromCenter = Math.abs(imageCenter - viewportCenter)
      // Zone de visibilité plus large pour que le texte reste affiché plus longtemps
      const maxDistance = windowHeight * 0.7
      
      if (distanceFromCenter < maxDistance && imageTop < windowHeight && imageBottom > 0) {
        // Image visible près du centre - calculer l'opacité
        const visibility = 1 - (distanceFromCenter / maxDistance)
        // Courbe conservée pour garder un vrai pic d'opacité au centre,
        // mais avec une zone active plus large le texte reste affiché plus longtemps
        let opacity = Math.max(0, Math.min(1, visibility ** 2))

        textWrapper.style.opacity = opacity
        // On ne masque plus brutalement le texte tant qu'il est dans la zone
        if (opacity > 0.05) {
          textWrapper.style.display = 'block'
        } else {
          textWrapper.style.display = 'none'
        }
        
        // Déterminer quelle slide est la plus visible
        if (visibility > maxVisibility) {
          maxVisibility = visibility
          activeIndex = index
        }
      } else {
        // Image complètement en dehors de la zone : cacher le texte
        textWrapper.style.opacity = '0'
        textWrapper.style.display = 'none'
      }
    })
    // Les indicateurs de pagination ont été retirés : plus de logique associée ici
  }
}
