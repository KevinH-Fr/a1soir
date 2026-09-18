import { Controller } from "@hotwired/stimulus"
import { destroyAnalysesCharts, mountAnalysesCharts } from "../admin/analyses/charts"

// Filtres Analyses : les liens portent data-turbo-stream (Hotwire natif).
// Ce contrôleur gère uniquement ce que Turbo ne fait pas : historique URL +
// cycle de vie Chart.js autour du replace du dashboard.
export default class extends Controller {
  connect() {
    this.pendingUrl = null
    this.onClick = this.onClick.bind(this)
    this.onBeforeStreamRender = this.onBeforeStreamRender.bind(this)

    this.element.addEventListener("click", this.onClick, true)
    document.addEventListener("turbo:before-stream-render", this.onBeforeStreamRender)
  }

  disconnect() {
    this.element.removeEventListener("click", this.onClick, true)
    document.removeEventListener("turbo:before-stream-render", this.onBeforeStreamRender)
  }

  onClick(event) {
    const link = event.target.closest("a[data-turbo-stream]")
    if (!link || !this.element.contains(link)) return
    this.pendingUrl = link.href
  }

  onBeforeStreamRender(event) {
    const originalRender = event.detail.render
    event.detail.render = (streamElement) => {
      const target = streamElement.getAttribute("target")

      if (target === "analyses_dashboard") {
        const dashboard = document.getElementById("analyses_dashboard")
        if (dashboard) destroyAnalysesCharts(dashboard)
      }

      originalRender(streamElement)

      if (target === "analyses_dashboard") {
        mountAnalysesCharts(document.getElementById("analyses_dashboard") || document)
        if (this.pendingUrl) {
          history.pushState({ analysesFilter: true }, "", this.pendingUrl)
          this.pendingUrl = null
        }
      }
    }
  }
}
