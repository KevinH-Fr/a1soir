import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "item"]
  static values = {
    delay: { type: Number, default: 200 }
  }

  connect() {
    // Cacher tous les éléments au départ
    this.hideAll()
    
    // Observer la section pour détecter quand elle devient visible
    this.setupObserver()
  }

  hideAll() {
    // Cacher la card
    if (this.hasCardTarget) {
      this.cardTarget.style.opacity = "0"
      this.cardTarget.style.transform = "translateY(50px) scale(0.95)"
      this.cardTarget.style.transition = "opacity 0.8s ease, transform 0.8s ease"
    }
    
    // Cacher tous les éléments internes
    this.itemTargets.forEach(item => {
      item.style.opacity = "0"
      item.style.transform = "translateY(30px)"
      item.style.transition = "opacity 0.6s ease, transform 0.6s ease"
    })
  }

  showCard() {
    if (this.hasCardTarget) {
      this.cardTarget.style.opacity = "1"
      this.cardTarget.style.transform = "translateY(0) scale(1)"
      
      // Afficher les éléments séquentiellement après un court délai
      setTimeout(() => {
        this.showItemsSequentially()
      }, 300)
    }
  }

  showItemsSequentially() {
    this.itemTargets.forEach((item, index) => {
      setTimeout(() => {
        item.style.opacity = "1"
        item.style.transform = "translateY(0)"
      }, index * this.delayValue)
    })
  }

  setupObserver() {
    const options = {
      root: null,
      rootMargin: '0px',
      threshold: 0.2
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.showCard()
        } else {
          this.hideAll()
        }
      })
    }, options)

    this.observer.observe(this.element)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}

