import { Controller } from "@hotwired/stimulus"
import { ZONES, drawRuler } from "../mensuration/figure_zones"

export default class extends Controller {
  static targets = ["ruler", "input"]
  static values = { clip: String, label: String }

  connect() {
    this.paint()
    this.focusInput()
  }

  focusInput() {
    if (!this.hasInputTarget) return

    const field = this.inputTarget
    requestAnimationFrame(() => {
      field.focus({ preventScroll: true })
    })
  }

  input() {
    this.paint()
  }

  paint() {
    const spec = ZONES[this.clipValue]
    if (!spec || !this.hasRulerTarget) return

    drawRuler(this.rulerTarget, spec, this.measureLabel())
  }

  measureLabel() {
    const name = this.labelValue || ""
    const value = this.inputTarget?.value?.toString().trim()
    if (name && value) return `${name} · ${value} cm`
    if (name) return `${name} · cm`
    return value ? `${value} cm` : "cm"
  }
}
