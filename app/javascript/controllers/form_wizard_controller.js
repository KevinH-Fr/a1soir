import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "bar", "caption", "prev", "next", "submit", "fill", "destroy"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.enterFromPrev = false
    this.show()
  }

  next() {
    const guide = this.currentGuide()
    if (guide && !guide.atLast) {
      if (!guide.validateCurrent()) return
      guide.nextField()
      this.updateChrome()
      return
    }

    if (!this.validateCurrent()) return
    if (this.indexValue < this.stepTargets.length - 1) {
      this.enterFromPrev = false
      this.indexValue++
      this.show()
    }
  }

  prev() {
    const guide = this.currentGuide()
    if (guide && !guide.atFirst) {
      guide.prevField()
      this.updateChrome()
      return
    }

    if (this.indexValue > 0) {
      this.enterFromPrev = true
      this.indexValue--
      this.show()
    }
  }

  // Dev only : préremplit les champs de l'étape (ou du champ guidé) affichée.
  fillStep() {
    const guide = this.currentGuide()
    if (guide) {
      const root = guide.currentFieldRoot()
      if (root) this.fillControls(root)
      return
    }

    const step = this.stepTargets[this.indexValue]
    if (step) this.fillControls(step)
  }

  fillControls(root) {
    root.querySelectorAll("input, select, textarea").forEach((el) => this.fillControl(el))
  }

  fillControl(el) {
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
      el.value = "Durand"
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
  }

  validateCurrent() {
    const guide = this.currentGuide()
    if (guide) return guide.validateCurrent()

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
    this.stepTargets.forEach((step, i) => {
      step.classList.toggle("d-none", i !== this.indexValue)
    })

    const guide = this.currentGuide()
    if (guide) {
      if (this.enterFromPrev) guide.enterFromEnd()
      else guide.enterFromStart()
    }

    this.updateChrome()
  }

  updateChrome() {
    const totalSteps = this.stepTargets.length
    const last = this.indexValue === totalSteps - 1
    const guide = this.currentGuide()
    const hidePrev = this.indexValue === 0 && (!guide || guide.atFirst)

    if (this.hasPrevTarget) this.prevTarget.classList.toggle("d-none", hidePrev)
    if (this.hasNextTarget) this.nextTarget.classList.toggle("d-none", last)
    if (this.hasSubmitTarget) this.submitTarget.classList.toggle("d-none", !last)
    if (this.hasFillTarget) this.fillTarget.classList.toggle("d-none", last)
    if (this.hasDestroyTarget) this.destroyTarget.classList.toggle("d-none", !last)

    const { current, total } = this.progressUnits()
    const percent = Math.round((current / total) * 100)
    if (this.hasBarTarget) {
      this.barTarget.style.width = `${percent}%`
      this.barTarget.closest(".progress")?.setAttribute("aria-valuenow", String(percent))
    }
    if (this.hasCaptionTarget) {
      this.captionTarget.textContent = this.captionTarget.dataset.template
        .replace("%{current}", String(current))
        .replace("%{total}", String(total))
    }

    document.querySelector("[data-mensuration-shell]")?.classList.toggle(
      "mensuration-shell--guided",
      Boolean(guide?.figureVisible)
    )
  }

  currentGuide() {
    const step = this.stepTargets[this.indexValue]
    const el = step?.querySelector("[data-controller~='measure-guide']")
    if (!el) return null
    return this.application.getControllerForElementAndIdentifier(el, "measure-guide")
  }

  progressUnits() {
    let current = 0
    let total = 0

    this.stepTargets.forEach((step, i) => {
      const guideEl = step.querySelector("[data-controller~='measure-guide']")
      const count = guideEl
        ? guideEl.querySelectorAll("[data-measure-guide-target='field']").length
        : 1
      total += count
      if (i < this.indexValue) {
        current += count
      } else if (i === this.indexValue) {
        const guide = this.currentGuide()
        current += guide ? guide.indexValue + 1 : 1
      }
    })

    return { current: Math.max(current, 1), total: Math.max(total, 1) }
  }
}
