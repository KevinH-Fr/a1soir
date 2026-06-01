import { Controller } from "@hotwired/stimulus"

// Ferme le menu navbar mobile au clic en dehors du <nav> (navbar-expand-xxl, < 1400px).
export default class extends Controller {
  static targets = ["collapse"]

  static mobileQuery = "(max-width: 1399.98px)"

  connect() {
    this.boundOnDocumentClick = this.onDocumentClick.bind(this)
    document.addEventListener("click", this.boundOnDocumentClick)
  }

  disconnect() {
    document.removeEventListener("click", this.boundOnDocumentClick)
  }

  onDocumentClick(event) {
    if (!window.matchMedia(this.constructor.mobileQuery).matches) return
    if (!this.hasCollapseTarget) return

    const collapseEl = this.collapseTarget
    if (!collapseEl.classList.contains("show")) return
    if (this.element.contains(event.target)) return

    const instance = bootstrap.Collapse.getInstance(collapseEl)
    if (instance) {
      instance.hide()
    }
  }
}
