import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "bar", "caption", "prev", "next", "submit"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.show()
  }

  next() {
    if (!this.validateCurrent()) return
    if (this.indexValue < this.stepTargets.length - 1) {
      this.indexValue++
      this.show()
    }
  }

  prev() {
    if (this.indexValue > 0) {
      this.indexValue--
      this.show()
    }
  }

  validateCurrent() {
    const fields = this.stepTargets[this.indexValue].querySelectorAll("[required]")
    for (const field of fields) {
      if (!field.checkValidity()) {
        field.reportValidity()
        return false
      }
    }
    return true
  }

  show() {
    const total = this.stepTargets.length
    this.stepTargets.forEach((step, i) => {
      step.classList.toggle("d-none", i !== this.indexValue)
    })

    const last = this.indexValue === total - 1
    if (this.hasPrevTarget) this.prevTarget.classList.toggle("d-none", this.indexValue === 0)
    if (this.hasNextTarget) this.nextTarget.classList.toggle("d-none", last)
    if (this.hasSubmitTarget) this.submitTarget.classList.toggle("d-none", !last)

    const percent = Math.round(((this.indexValue + 1) / total) * 100)
    if (this.hasBarTarget) {
      this.barTarget.style.width = `${percent}%`
      this.barTarget.closest(".progress")?.setAttribute("aria-valuenow", String(percent))
    }
    if (this.hasCaptionTarget) {
      this.captionTarget.textContent = this.captionTarget.dataset.template
        .replace("%{current}", String(this.indexValue + 1))
        .replace("%{total}", String(total))
    }
  }
}
