import { Controller } from "@hotwired/stimulus"
import { ZONES, drawRuler, hideRuler, setRulerLabel } from "../mensuration/figure_zones"

export default class extends Controller {
  static targets = ["field", "figure", "ruler", "title", "howto"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.onMeasureInput = () => this.refreshRulerLabel()
    this.showField()
  }

  disconnect() {
    this.unbindMeasureInput()
  }

  get atFirst() {
    return this.indexValue <= 0
  }

  get atLast() {
    return this.indexValue >= this.fieldTargets.length - 1
  }

  get figureVisible() {
    return Boolean(this.fieldTargets[this.indexValue]?.dataset.clip)
  }

  enterFromStart() {
    this.indexValue = 0
    this.showField()
  }

  enterFromEnd() {
    this.indexValue = Math.max(this.fieldTargets.length - 1, 0)
    this.showField()
  }

  nextField() {
    if (this.atLast) return
    this.indexValue++
    this.showField()
  }

  prevField() {
    if (this.atFirst) return
    this.indexValue--
    this.showField()
  }

  validateCurrent() {
    const field = this.fieldTargets[this.indexValue]
    if (!field) return true

    for (const input of field.querySelectorAll("[required]")) {
      if (!input.checkValidity()) {
        input.reportValidity()
        return false
      }
    }
    return true
  }

  currentFieldRoot() {
    return this.fieldTargets[this.indexValue]
  }

  showField() {
    this.fieldTargets.forEach((field, i) => {
      field.classList.toggle("d-none", i !== this.indexValue)
    })
    this.syncCaption()
    this.highlight()
  }

  syncCaption() {
    const field = this.fieldTargets[this.indexValue]
    const title = field?.dataset.title || ""
    const howto = field?.dataset.howto || ""

    if (this.hasTitleTarget) this.titleTarget.textContent = title
    if (this.hasHowtoTarget) {
      this.howtoTarget.textContent = howto
      this.howtoTarget.classList.toggle("d-none", !howto)
    }
    this.element.classList.toggle("mensuration-guide--howto", Boolean(howto))
  }

  highlight() {
    const clip = this.fieldTargets[this.indexValue]?.dataset.clip
    this.element.classList.toggle("mensuration-guide--plain", !clip)
    if (this.hasFigureTarget) this.figureTarget.classList.toggle("d-none", !clip)
    this.bindMeasureInput()
    this.paintSvg(clip)
  }

  paintSvg(clip) {
    if (!this.hasRulerTarget) return
    const spec = ZONES[clip]
    if (!spec) {
      hideRuler(this.rulerTarget)
      return
    }
    drawRuler(this.rulerTarget, spec, this.measureLabel())
  }

  bindMeasureInput() {
    this.unbindMeasureInput()
    this.measureInput = this.currentFieldRoot()?.querySelector("input, textarea")
    this.measureInput?.addEventListener("input", this.onMeasureInput)
  }

  unbindMeasureInput() {
    this.measureInput?.removeEventListener("input", this.onMeasureInput)
    this.measureInput = null
  }

  refreshRulerLabel() {
    if (this.hasRulerTarget) setRulerLabel(this.rulerTarget, this.measureLabel())
  }

  measureLabel() {
    const name = this.currentFieldRoot()?.dataset.ruler || ""
    const value = this.measureInput?.value?.toString().trim()
    if (name && value) return `${name} · ${value} cm`
    if (name) return `${name} · cm`
    return value ? `${value} cm` : "cm"
  }
}
