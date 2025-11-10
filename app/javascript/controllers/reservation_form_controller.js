import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cta", "collapse"]

  connect() {
    this.boundUpdate = this.update.bind(this)

    if (this.hasCollapseTarget) {
      this.collapseTarget.addEventListener("shown.bs.collapse", this.boundUpdate)
      this.collapseTarget.addEventListener("hidden.bs.collapse", this.boundUpdate)
    }

    this.update()
  }

  disconnect() {
    if (this.hasCollapseTarget) {
      this.collapseTarget.removeEventListener("shown.bs.collapse", this.boundUpdate)
      this.collapseTarget.removeEventListener("hidden.bs.collapse", this.boundUpdate)
    }
  }

  update() {
    if (!this.hasCtaTarget) return

    const isShown = this.hasCollapseTarget && this.collapseTarget.classList.contains("show")
    this.ctaTarget.classList.toggle("d-none", isShown)
  }
}

