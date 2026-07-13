import { Controller } from "@hotwired/stimulus"

// Déclenche un événement GA4 via gtag (page initiale ou Turbo Stream append).
export default class extends Controller {
  static values = {
    eventName: String,
    payload: Object
  }

  connect() {
    if (typeof gtag !== "function") return

    gtag("event", this.eventNameValue, this.payloadValue)
  }
}
