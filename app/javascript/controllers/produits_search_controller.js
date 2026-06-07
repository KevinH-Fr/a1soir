import { Controller } from "@hotwired/stimulus"

// Debounce la recherche produits et synchronise l'URL du navigateur
// (évite les réponses Turbo en retard et garde le back_url cohérent).
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  connect() {
    this.timeout = null
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  queueSubmit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  syncUrl() {
    const url = new URL(this.element.action, window.location.origin)
    const params = new URLSearchParams(new FormData(this.element))

    params.forEach((value, key) => {
      if (value === "") params.delete(key)
    })

    url.search = params.toString()
    history.pushState({}, "", url)
  }
}
