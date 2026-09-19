import { Controller } from "@hotwired/stimulus"
import { updateAnalysesChartFromRaw } from "../admin/analyses/charts"

// Bascule Quantité / CA : charts (swap config Chart.js) ou panneaux (show/hide).
export default class extends Controller {
  static targets = ["button", "panel", "canvas", "center"]
  static values = {
    active: { type: String, default: "qty" }
  }

  connect() {
    this.syncUi()
  }

  select(event) {
    const key = event.currentTarget.dataset.segmentKey
    if (!key || key === this.activeValue) return

    this.activeValue = key
    this.syncUi()
  }

  syncUi() {
    this.buttonTargets.forEach((btn) => {
      const active = btn.dataset.segmentKey === this.activeValue
      btn.setAttribute("aria-pressed", active ? "true" : "false")
      btn.classList.toggle("active", active)
      btn.classList.toggle("btn-dark", active)
      btn.classList.toggle("btn-outline-secondary", !active)
    })

    this.panelTargets.forEach((panel) => {
      panel.classList.toggle("d-none", panel.dataset.segmentKey !== this.activeValue)
    })

    this.updateChart()
  }

  updateChart() {
    if (!this.hasCanvasTarget) return

    const canvas = this.canvasTarget
    const rawAttr = this.activeValue === "ca" ? "chartCa" : "chartQty"
    const rawJson = canvas.dataset[rawAttr]
    if (!rawJson) return

    let raw
    try {
      raw = JSON.parse(rawJson)
    } catch (e) {
      console.error("Analyses segment toggle: invalid chart config", e)
      return
    }

    canvas.dataset.analysesChart = rawJson
    updateAnalysesChartFromRaw(canvas, raw)
    this.updateCenter()
  }

  updateCenter() {
    if (!this.hasCenterTarget) return

    const canvas = this.canvasTarget
    const centerAttr = this.activeValue === "ca" ? "centerCa" : "centerQty"
    const linesJson = canvas.dataset[centerAttr]
    if (!linesJson) return

    let lines
    try {
      lines = JSON.parse(linesJson)
    } catch (e) {
      return
    }

    this.centerTarget.innerHTML = ""
    ;(lines || []).forEach((line, index) => {
      const span = document.createElement("span")
      span.className = `analyses-donut-center__line analyses-donut-center__line--${index}`
      span.textContent = line
      this.centerTarget.appendChild(span)
    })
  }
}
