import { Controller } from "@hotwired/stimulus"

// Aligne ?step= sur l'étape affichée (hors du turbo-frame remplacé à chaque étape).
export default class extends Controller {
  static values = { editing: Boolean }

  connect() {
    this.syncFromDom()
    this.onRender = () => requestAnimationFrame(() => this.syncFromDom())
    document.addEventListener("turbo:render", this.onRender)
  }

  disconnect() {
    document.removeEventListener("turbo:render", this.onRender)
  }

  syncAfterSubmit(event) {
    if (!event.detail?.success) return

    const form = event.target
    if (!form?.action?.includes("/step")) return

    const headerStep = event.detail.fetchResponse?.response?.headers?.get("X-Mensuration-Step")
    if (headerStep) {
      this.syncWithStep(headerStep)
      return
    }

    requestAnimationFrame(() => this.syncFromDom())
  }

  syncFromDom() {
    const frame = document.getElementById("mensuration_step")
    const step = frame?.dataset?.mensurationStep
    this.syncWithStep(step)
  }

  syncWithStep(step) {
    if (!step) return

    const url = new URL(window.location.href)
    if (url.searchParams.get("step") === step) return

    url.searchParams.set("step", step)
    if (this.editingValue) url.searchParams.set("edit", "1")
    else url.searchParams.delete("edit")

    history.replaceState(history.state, "", url)
  }
}
