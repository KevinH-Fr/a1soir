import { Controller } from "@hotwired/stimulus"

// Listes publiques : /fr|en/produits, /fr|en/produits/:slug-:id, costumes.
const LISTING_PATH = /^\/(?:fr|en)\/(?:produits(?:\/[^/]+)?|produits_costumes_deguisements)\/?$/

// Le href reste @back_url. On ne revient en arrière que si la page précédente
// est vraiment la liste, pour réafficher son scroll (.public-scroll).
export default class extends Controller {
  back(event) {
    if (!this.shouldRestore(event)) return

    event.preventDefault()
    history.back()
  }

  shouldRestore(event) {
    if (event.defaultPrevented) return false
    if (event.button !== 0) return false
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return false
    if (history.length <= 1) return false

    return this.referrerIsListing()
  }

  referrerIsListing() {
    if (!document.referrer) return false

    let url
    try {
      url = new URL(document.referrer)
    } catch (_error) {
      return false
    }

    if (url.origin !== window.location.origin) return false

    return LISTING_PATH.test(url.pathname)
  }
}
