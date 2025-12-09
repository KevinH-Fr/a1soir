// app/javascript/controllers/scroll_reveal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]

  connect() {
    // Ajouter une classe au container pour indiquer que JS est actif
    this.element.classList.add("js-scroll-reveal-active")
    this.setupIntersectionObserver()
  }

  setupIntersectionObserver() {
    const options = {
      root: null,
      rootMargin: "0px 0px -50px 0px", // Déclenche quand l'élément est à 50px du bas
      threshold: 0.1
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-revealed")
          // Optionnel : arrêter d'observer une fois révélé pour la performance
          // this.observer.unobserve(entry.target)
        }
      })
    }, options)

    // Observer tous les items
    this.itemTargets.forEach(item => {
      this.observer.observe(item)
    })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}

