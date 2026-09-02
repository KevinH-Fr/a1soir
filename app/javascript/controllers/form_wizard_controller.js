import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "bar", "caption", "prev", "next", "submit", "fill"]
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

  // Dev only : préremplit tous les champs de l'étape affichée (sauf fichier / champs disabled).
  fillStep() {
    const step = this.stepTargets[this.indexValue]
    if (!step) return

    step.querySelectorAll("input, select, textarea").forEach((el) => {
      if (el.disabled || el.type === "hidden" || el.type === "file" || el.type === "submit" || el.type === "button") return

      const name = el.name || ""

      if (el.type === "date") {
        el.value = "2026-12-15"
      } else if (el.tagName === "SELECT") {
        const option = [...el.options].find((o) => o.value)
        if (option) el.value = option.value
      } else if (el.tagName === "TEXTAREA") {
        el.value = "Près du corps, manches courtes"
      } else if (el.type === "tel" || name.includes("[telephone]")) {
        el.value = "0612345678"
      } else if (name.includes("[prenom]")) {
        el.value = "Anna"
      } else if (name.includes("[nom]")) {
        el.value = "Test"
      } else if (name.includes("[adresse]")) {
        el.value = "27 Boulevard Carnot"
      } else if (name.includes("[cp]")) {
        el.value = "06400"
      } else if (name.includes("[ville]")) {
        el.value = "Cannes"
      } else if (name.includes("hauteur_talons")) {
        el.value = "8"
      } else if (name.includes("[hauteur]") || name.includes("hauteur")) {
        el.value = "168"
      } else if (name.includes("pointure")) {
        el.value = "39"
      } else if (name.includes("tour_") || name.includes("largeur") || name.includes("longueur")) {
        el.value = "90"
      } else {
        el.value = "40"
      }

      el.dispatchEvent(new Event("input", { bubbles: true }))
      el.dispatchEvent(new Event("change", { bubbles: true }))
    })
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
    if (this.hasFillTarget) this.fillTarget.classList.toggle("d-none", last)

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
