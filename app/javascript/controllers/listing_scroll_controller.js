import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "public-listing-scroll"

// Le scroll public est sur .public-scroll. Un retour arrière recharge souvent
// la liste, et le navigateur ne restaure pas ce conteneur. On ne réapplique
// la position que pour une navigation back/forward vers la même adresse.
export default class extends Controller {
  connect() {
    this.onPageHide = () => this.save()
    window.addEventListener("pagehide", this.onPageHide)
    this.restore()
  }

  disconnect() {
    window.removeEventListener("pagehide", this.onPageHide)
  }

  save() {
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify({
      key: this.storageKey(),
      top: this.element.scrollTop
    }))
  }

  restore() {
    const navigation = performance.getEntriesByType("navigation")[0]
    if (navigation?.type !== "back_forward") return

    const saved = this.read()
    if (!saved || saved.key !== this.storageKey()) return

    this.element.scrollTop = saved.top
  }

  read() {
    const raw = sessionStorage.getItem(STORAGE_KEY)
    if (!raw) return null

    try {
      return JSON.parse(raw)
    } catch (_error) {
      return null
    }
  }

  storageKey() {
    return `${location.pathname}${location.search}`
  }
}
