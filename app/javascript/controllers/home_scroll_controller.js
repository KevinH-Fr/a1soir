import { Controller } from "@hotwired/stimulus"

// Contrôleur pour les animations de la page home :
// - 3 textes qui apparaissent de gauche à droite au scroll
// - badge indiquant la position de scroll
// - zoom progressif sur l'image pleine page pendant le scroll
export default class extends Controller {
  static targets = ["text", "scrollBadge", "image"]

  connect() {
    this.handleScroll = this.handleScroll.bind(this)
    // Textes successifs
    this.texts = [
      "Mariages & tenues de soirée",
      "Vente et location",
      "Pour tous vos événements"
    ]

    window.addEventListener("scroll", this.handleScroll, { passive: true })
    this.handleScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
  }

  handleScroll() {
    const docHeight = document.documentElement.scrollHeight - window.innerHeight
    const scrollY = window.scrollY
    const progress = docHeight > 0 ? scrollY / docHeight : 0

    // Met à jour le badge de position de scroll
    if (this.hasScrollBadgeTarget) {
      const percent = Math.max(0, Math.min(100, progress * 100))
      const roundedPercent = Math.round(percent)
      const roundedY = Math.round(scrollY)
      this.scrollBadgeTarget.textContent = `${roundedY}px · ${roundedPercent}%`
    }

    // Animation simple au scroll pour les 3 textes : apparition de gauche à droite
    if (this.hasTextTarget) {
      const minScrollToStart = 0
      const totalScrollForTexts = window.innerHeight * 4
      const rawLocal = (scrollY - minScrollToStart) / totalScrollForTexts
      const local = Math.max(0, Math.min(1, rawLocal))
      
      if (local <= 0) {
        this.textTarget.textContent = ""
        this.textTarget.style.opacity = 0
        this.textTarget.style.clipPath = "inset(0 100% 0 0)"
      } else {
        const segmentCount = this.texts.length
        const segmentLength = 1 / segmentCount
        let targetIndex = Math.floor(local / segmentLength)
        if (targetIndex >= segmentCount) targetIndex = segmentCount - 1

        const segmentStart = targetIndex * segmentLength
        const segmentProgress = segmentLength > 0 ? (local - segmentStart) / segmentLength : 0

        const currentText = this.texts[targetIndex]
        const revealPhase = 0.6    // 60% du segment pour l'apparition
        const fadePhaseStart = 0.85 // 85% -> 100% : fade out

        if (segmentProgress <= 0) {
          this.textTarget.textContent = ""
          this.textTarget.style.opacity = 0
          this.textTarget.style.clipPath = "inset(0 100% 0 0)"
        } else if (segmentProgress < revealPhase) {
          // Phase d'apparition de gauche à droite
          const revealProgress = segmentProgress / revealPhase
          const clipRight = 100 - (revealProgress * 100) // De 100% à 0%
          this.textTarget.textContent = currentText
          this.textTarget.style.opacity = 1
          this.textTarget.style.clipPath = `inset(0 ${clipRight}% 0 0)`
        } else if (segmentProgress < fadePhaseStart) {
          // Texte entièrement visible
          this.textTarget.textContent = currentText
          this.textTarget.style.opacity = 1
          this.textTarget.style.clipPath = "inset(0 0% 0 0)"
        } else {
          // Phase de disparition
          const fadeProgress = (segmentProgress - fadePhaseStart) / (1 - fadePhaseStart)
          const opacity = 1 - Math.max(0, Math.min(1, fadeProgress))
          this.textTarget.textContent = currentText
          this.textTarget.style.opacity = opacity
          this.textTarget.style.clipPath = "inset(0 0% 0 0)"
        }
      }
    }

    // Zoom progressif sur l'image pleine page avec déplacement vers la droite et vers l'avant
    // Le zoom ne commence qu'après que les 3 textes aient été affichés
    if (this.hasImageTarget) {
      const totalScrollForTexts = window.innerHeight * 4
      const zoomStartOffset = totalScrollForTexts // Le zoom commence après les textes
      const zoomDistance = window.innerHeight * 6 // Distance pour le zoom (réduite pour animation plus rapide)
      const fadeStartOffset = zoomStartOffset + zoomDistance * 0.85 // Le fade commence à 85% du zoom
      const fadeDistance = zoomDistance * 0.15 // Les 15% finaux pour le fade out
      
      // Si on n'a pas encore atteint le début du zoom, l'image reste à scale 1
      if (scrollY < zoomStartOffset) {
        this.imageTarget.style.transform = `scale(1) translate(0, 0)`
        this.imageTarget.style.opacity = 1
      } else if (scrollY < fadeStartOffset) {
        // Phase de zoom vers l'avant avec léger déplacement vers la gauche (mouvement linéaire)
        const zoomScroll = scrollY - zoomStartOffset
        const rawZoomProgress = Math.min(zoomScroll / (fadeStartOffset - zoomStartOffset), 1)
        // Mouvement linéaire (pas d'easing)
        const zoomProgress = rawZoomProgress
        const minScale = 1
        const maxScale = 4.0 // Zoom important
        const scale = minScale + (maxScale - minScale) * zoomProgress
        
        // Déplacement vers la droite
        const maxTranslateX = window.innerWidth * 0.30 // Déplacement max de 15% vers la droite
        const translateX = maxTranslateX * zoomProgress
        
        // Déplacement vers l'avant (vers le haut)
        const maxTranslateY = -window.innerHeight * 0.15 // Déplacement max de 15% vers l'avant
        const translateY = maxTranslateY * zoomProgress
        
        this.imageTarget.style.transform = `scale(${scale}) translate(${translateX}px, ${translateY}px)`
        this.imageTarget.style.opacity = 1
      } else {
        // Phase de fade out à la fin du zoom
        const fadeScroll = scrollY - fadeStartOffset
        const fadeProgress = Math.min(fadeScroll / fadeDistance, 1)
        const opacity = 1 - fadeProgress
        
        // Le zoom reste au maximum pendant le fade avec le déplacement maximal
        const maxScale = 4.0
        const maxTranslateX = window.innerWidth * 0.30
        const maxTranslateY = -window.innerHeight * 0.15
        this.imageTarget.style.transform = `scale(${maxScale}) translate(${maxTranslateX}px, ${maxTranslateY}px)`
        this.imageTarget.style.opacity = opacity
      }
    }
  }

}


