import { Controller } from "@hotwired/stimulus"

// Joue 1 · 2 · 3 quand les étapes sont visibles, puis les laisse fixes.
// La séquence ne repart que si elles sont ressorties de l'écran.
export default class extends Controller {
  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.intersectionRatio >= 0.55) {
            this.element.classList.add("is-steps-in")
          } else if (!entry.isIntersecting) {
            this.element.classList.remove("is-steps-in")
          }
        })
      },
      { root: this.scrollRoot(), threshold: [0, 0.55] }
    )

    this.observer.observe(this.element)
  }

  scrollRoot() {
    let node = this.element.parentElement

    while (node && node !== document.body) {
      const overflow = getComputedStyle(node).overflowY
      if (overflow === "auto" || overflow === "scroll") return node
      node = node.parentElement
    }

    return null
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }
}
