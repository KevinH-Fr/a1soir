import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "image", "indicator", "indicators"]

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
      const maxDistance = windowHeight * 0.6 // Zone de visibilité plus large pour chevauchement
      
      if (distanceFromCenter < maxDistance && imageTop < windowHeight && imageBottom > 0) {
        // Image visible près du centre - calculer l'opacité
        const visibility = 1 - (distanceFromCenter / maxDistance)
        let opacity = Math.max(0, Math.min(1, visibility))
        
        // Fade in/out plus rapide pour transition plus rapide
        if (opacity < 0.3) {
          opacity = opacity / 0.3 // Fade in plus rapide
        }
        
        textWrapper.style.opacity = opacity
        textWrapper.style.display = 'block'
        
        // Déterminer quelle slide est la plus visible
        if (visibility > maxVisibility) {
          maxVisibility = visibility
          activeIndex = index
        }
      } else {
        // Image pas visible - cacher le texte
        textWrapper.style.opacity = '0'
        textWrapper.style.display = 'none'
      }
    })
    
    // Afficher/masquer les indicateurs - apparaissent plus tard et disparaissent plus tôt
    // Apparaissent quand la section est bien entrée dans le viewport (rect.top <= -100px)
    // Disparaissent avant la fin (quand il reste moins de 30% de la hauteur de la fenêtre)
    const showThreshold = -100 // Apparaissent après avoir scrollé 100px dans la section
    const hideThreshold = windowHeight * 0.3 // Disparaissent quand il reste moins de 30% de la fenêtre
    
    if (rect.top <= showThreshold && rect.bottom > hideThreshold) {
      this.indicatorsTarget.style.opacity = '1'
    } else {
      this.indicatorsTarget.style.opacity = '0'
    }
    
    // Mettre à jour les indicateurs - remplissage binaire (vide ou plein)
    this.indicatorTargets.forEach((indicator, index) => {
      const fillBar = indicator.querySelector('.indicator-fill')
      if (!fillBar) return
      
      // Si cette slide est active ou si on a déjà passé cette slide, la remplir complètement
      if (index <= activeIndex && activeIndex >= 0) {
        // Slide active ou passée - complètement remplie
        fillBar.style.width = '100%'
      } else {
        // Slides futures - vides
        fillBar.style.width = '0%'
      }
    })
  }
}

