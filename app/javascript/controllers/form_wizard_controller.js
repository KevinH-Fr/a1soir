import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "bar", "caption", "prev", "next", "submit", "fill", "home", "progress", "form"]
  static values = {
    index: { type: Number, default: 0 },
    saved: { type: Boolean, default: false },
    draftUrl: String,
    draftError: { type: String, default: "Could not save your progress." },
    guideIndex: { type: Number, default: 0 },
    restoreGuide: { type: Boolean, default: false }
  }

  connect() {
    this.enterFromPrev = false
    this.show()
  }

  formElement() {
    if (this.hasFormTarget) return this.formTarget
    // Évite le <form> des button_to Femme/Homme (premier form du DOM).
    return this.element.querySelector("form[data-form-wizard-target='form']")
  }

  // Entrée dans un champ de mesure = Continuer. Les coordonnées n'avancent qu'au clic.
  advanceOnEnter(event) {
    if (event.repeat) return
    if (event.target instanceof HTMLTextAreaElement) return
    if (event.target.closest("button, input[type=submit]")) return

    if (this.isFinalSubmit()) return

    event.preventDefault()
    if (this.onIdentityStep()) return
    this.next()
  }

  guardSubmit(event) {
    if (this.isFinalSubmit()) return

    event.preventDefault()
    // L'autofill du navigateur envoie le formulaire dès que les coordonnées sont pleines.
    if (this.onIdentityStep()) return
    this.next()
  }

  onIdentityStep() {
    return this.stepTargets[this.indexValue]?.classList.contains("mensuration-form__identity")
  }

  isFinalSubmit() {
    const last = this.indexValue === this.stepTargets.length - 1
    const guide = this.currentGuide()
    return last && (!guide || guide.atLast)
  }

  async next() {
    const guide = this.currentGuide()
    if (guide && !guide.atLast) {
      if (!guide.validateCurrent()) return
      const nextGuideIndex = guide.indexValue + 1
      if (!(await this.persistDraft(this.indexValue, nextGuideIndex))) return
      guide.nextField()
      this.updateChrome()
      return
    }

    if (!this.validateCurrent()) return
    if (this.indexValue < this.stepTargets.length - 1) {
      const nextIndex = this.indexValue + 1
      const nextStep = this.stepTargets[nextIndex]
      const hasGuide = Boolean(nextStep?.querySelector("[data-controller~='measure-guide']"))
      const guideIndex = hasGuide ? 0 : undefined
      if (!(await this.persistDraft(nextIndex, guideIndex))) return

      this.enterFromPrev = false
      this.restoreGuideValue = false
      this.indexValue = nextIndex
      this.show()
    }
  }

  async prev() {
    const guide = this.currentGuide()
    if (guide && !guide.atFirst) {
      const prevGuideIndex = guide.indexValue - 1
      if (!(await this.persistDraft(this.indexValue, prevGuideIndex))) return
      guide.prevField()
      this.updateChrome()
      return
    }

    if (this.indexValue > 0) {
      const prevIndex = this.indexValue - 1
      const prevStep = this.stepTargets[prevIndex]
      const prevGuideEl = prevStep?.querySelector("[data-controller~='measure-guide']")
      let guideIndex = undefined
      if (prevGuideEl) {
        const fieldCount = prevGuideEl.querySelectorAll("[data-measure-guide-target='field']").length
        guideIndex = Math.max(fieldCount - 1, 0)
      }

      // Index 0 = choix template : on enregistre quand même les saisies (min. identité).
      const draftIndex = Math.max(prevIndex, 1)
      if (!(await this.persistDraft(draftIndex, prevIndex >= 1 ? guideIndex : undefined))) return

      this.enterFromPrev = true
      this.restoreGuideValue = false
      this.indexValue = prevIndex
      this.show()
    }
  }

  // Dev only : préremplit l'étape affichée puis avance comme Continuer.
  async fillStep() {
    if (this.stepTargets[this.indexValue]?.hasAttribute("data-choice-step")) return

    const guide = this.currentGuide()
    if (guide) {
      const root = guide.currentFieldRoot()
      if (root) this.fillControls(root)
    } else {
      const step = this.stepTargets[this.indexValue]
      if (step) this.fillControls(step)
    }

    if (this.isFinalSubmit()) {
      if (this.hasSubmitTarget) this.submitTarget.click()
      else this.formElement()?.requestSubmit()
      return
    }

    await this.next()
  }

  fillControls(root) {
    root.querySelectorAll("input, select, textarea").forEach((el) => this.fillControl(el))
  }

  fillControl(el) {
    if (el.disabled || el.type === "hidden" || el.type === "file" || el.type === "submit" || el.type === "button") return

    const name = el.name || ""

    if (el.type === "date") {
      el.value = "2026-12-15"
    } else if (el.type === "number") {
      const min = el.min === "" ? -Infinity : Number(el.min)
      const max = el.max === "" ? Infinity : Number(el.max)
      let preferred = 80
      if (name.includes("hauteur_talons")) preferred = 8
      else if (name.includes("hauteur")) preferred = 168
      el.value = String(Math.min(max, Math.max(min, preferred)))
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

    const step = this.stepTargets[this.indexValue]
    if (!step) return true
    for (const input of step.querySelectorAll("input, select, textarea")) {
      if (input.disabled) continue
      if (!input.checkValidity()) {
        input.reportValidity()
        return false
      }
    }
    return true
  }

  show() {
    this.stepTargets.forEach((step, i) => {
      step.classList.toggle("d-none", i !== this.indexValue)
      if (i === this.indexValue) this.restoreStepValues(step)
    })

    const guide = this.currentGuide()
    if (guide) {
      if (this.enterFromPrev) {
        guide.enterFromEnd()
      } else if (this.restoreGuideValue) {
        guide.indexValue = Math.min(this.guideIndexValue, guide.fieldTargets.length - 1)
        guide.showField()
      } else {
        guide.enterFromStart()
      }
    }

    this.updateChrome()
  }

  updateChrome() {
    const totalSteps = this.stepTargets.length
    const last = this.indexValue === totalSteps - 1
    const guide = this.currentGuide()
    const startIndex = this.savedValue ? 1 : 0
    const atStart = this.indexValue === startIndex && (!guide || guide.atFirst)
    const showHome = this.savedValue && atStart
    const hidePrev = showHome || (!this.savedValue && atStart)

    const choiceStep = this.stepTargets[this.indexValue]?.hasAttribute("data-choice-step")

    if (this.hasProgressTarget) this.progressTarget.classList.toggle("d-none", choiceStep)
    if (this.hasHomeTarget) this.homeTarget.classList.toggle("d-none", !showHome)
    if (this.hasPrevTarget) this.prevTarget.classList.toggle("d-none", hidePrev)
    if (this.hasNextTarget) this.nextTarget.classList.toggle("d-none", last || choiceStep)
    if (this.hasSubmitTarget) this.submitTarget.classList.toggle("d-none", !last)
    if (this.hasFillTarget) this.fillTarget.classList.toggle("d-none", last)

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

  async persistDraft(wizardIndex, guideIndex = undefined) {
    if (!this.hasDraftUrlValue) return true

    const form = this.formElement()
    if (!form) return true

    const data = new FormData(form)
    data.append("wizard_index", String(wizardIndex))
    if (guideIndex !== undefined) data.append("guide_index", String(guideIndex))

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const response = await fetch(this.draftUrlValue, {
      method: "POST",
      body: data,
      headers: {
        "X-CSRF-Token": token,
        Accept: "application/json"
      },
      credentials: "same-origin"
    })

    if (response.ok) {
      this.stashSavedValues(form)
      const guide = this.currentGuide()
      guide?.stashFieldValues()
      return true
    }

    window.alert(this.draftErrorValue)
    return false
  }

  restoreStepValues(step) {
    if (!step) return

    step.querySelectorAll("input, textarea, select").forEach((el) => {
      const saved = el.dataset.initialValue
      if (saved == null || saved === "") return
      if (el.disabled) return
      if (el.tagName === "SELECT") {
        if (!el.value) el.value = saved
      } else if (!el.value?.trim()) {
        el.value = saved
      }
    })
  }

  stashSavedValues(root) {
    root.querySelectorAll("input, textarea, select").forEach((el) => {
      if (!el.name || el.disabled) return
      if (el.type === "file") return
      if (el.value) el.dataset.initialValue = el.value
    })
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

    // Le choix Femme/Homme reste navigable, mais hors compteur (c'est une porte, pas une saisie).
    this.stepTargets.forEach((step, i) => {
      if (step.hasAttribute("data-choice-step")) return

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
