import { Controller } from "@hotwired/stimulus"

// Déclenche un événement GA4 via gtag, et l'équivalent Meta / TikTok si le pixel est chargé.
// Par défaut à la connexion (page ou Turbo Stream). Le paiement du panier
// appelle track au submit, sans l'envoyer à l'affichage.
export default class extends Controller {
  static values = {
    eventName: String,
    payload: Object,
    metaEventName: String,
    metaPayload: Object,
    metaEventId: String,
    tiktokEventName: String,
    tiktokPayload: Object,
    tiktokEventId: String,
    trackOnConnect: { type: Boolean, default: true }
  }

  connect() {
    if (this.trackOnConnectValue) this.track()
  }

  track() {
    if (typeof gtag === "function") {
      gtag("event", this.eventNameValue, this.payloadValue)
    }
    this.trackMeta()
    this.trackTiktok()
  }

  trackMeta() {
    if (!this.hasMetaEventNameValue || typeof fbq !== "function") return

    if (this.hasMetaEventIdValue && this.metaEventIdValue) {
      fbq("track", this.metaEventNameValue, this.metaPayloadValue, { eventID: this.metaEventIdValue })
    } else {
      fbq("track", this.metaEventNameValue, this.metaPayloadValue)
    }
  }

  trackTiktok() {
    if (!this.hasTiktokEventNameValue || !window.ttq || typeof window.ttq.track !== "function") return

    if (this.hasTiktokEventIdValue && this.tiktokEventIdValue) {
      window.ttq.track(this.tiktokEventNameValue, this.tiktokPayloadValue, { event_id: this.tiktokEventIdValue })
    } else {
      window.ttq.track(this.tiktokEventNameValue, this.tiktokPayloadValue)
    }
  }
}
