import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]
  static values = {
    delay: { type: Number, default: 200 },
    triggerOffset: { type: Number, default: 150 }
  }

  connect() {
    console.log("🎬 Boutique text scroll controller connecté")
    console.log("📝 Nombre d'éléments trouvés:", this.itemTargets.length)
    
    // Initialiser tous les éléments comme invisibles
    this.hideAllItems()
    
    // Écouter le scroll pour animer en fonction de la position
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.handleScroll, { passive: true })
    this.handleScroll() // Appel initial
  }

  hideAllItems() {
    this.itemTargets.forEach(item => {
      item.style.opacity = "0"
      item.style.transform = "translateY(30px)"
    })
  }

  handleScroll() {
    const sectionRect = this.element.getBoundingClientRect()
    const windowHeight = window.innerHeight
    const sectionTop = sectionRect.top
    const sectionHeight = sectionRect.height
    
    // Vérifier si la section est dans le viewport
    if (sectionTop + sectionHeight < 0 || sectionTop > windowHeight) {
      // Si la section est hors du viewport, cacher tous les éléments
      this.hideAllItems()
      return
    }

    // Calculer la progression du scroll dans la section (0 à 1)
    // Quand sectionTop = windowHeight, progression = 0 (début)
    // Quand sectionTop = -sectionHeight, progression = 1 (fin)
    const scrollStart = windowHeight
    const scrollEnd = -sectionHeight
    const scrollRange = scrollStart - scrollEnd
    const currentPosition = scrollStart - sectionTop
    
    const scrollProgress = Math.max(0, Math.min(1, currentPosition / scrollRange))

    // Animer chaque élément en fonction de sa position dans la progression
    this.itemTargets.forEach((item, index) => {
      // Calculer quand chaque élément doit commencer à apparaître
      const segmentSize = 1 / this.itemTargets.length
      const elementStart = index * segmentSize
      const elementEnd = (index + 1) * segmentSize
      
      // Calculer la progression pour cet élément spécifique
      let elementProgress = 0
      if (scrollProgress >= elementStart) {
        if (scrollProgress >= elementEnd) {
          elementProgress = 1
        } else {
          // L'élément est en train d'apparaître
          elementProgress = (scrollProgress - elementStart) / segmentSize
        }
      }
      
      // Appliquer l'animation avec easing
      const easedProgress = this.easeOutCubic(elementProgress)
      const opacity = easedProgress
      const translateY = 30 * (1 - easedProgress)
      
      item.style.opacity = opacity.toString()
      item.style.transform = `translateY(${translateY}px)`
    })
  }

  easeOutCubic(t) {
    return 1 - Math.pow(1 - t, 3)
  }

  disconnect() {
    if (this.handleScroll) {
      window.removeEventListener('scroll', this.handleScroll)
    }
  }
}

