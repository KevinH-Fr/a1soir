import { Controller } from "@hotwired/stimulus"

// Clics sortants vers le téléphone ou l'itinéraire : pas de passage par Rails,
// l'événement GA4 part directement au clic (si gtag est chargé).
const OUTBOUND_EVENTS = [
  { selector: 'a[href^="tel:"]', eventName: "phone_call" },
  { selector: 'a[href^="https://www.google.com/maps/"], a[href^="https://maps.google.com/"]', eventName: "get_directions" }
]

export default class extends Controller {
  track(event) {
    if (typeof gtag !== "function") return

    const match = OUTBOUND_EVENTS.find(({ selector }) => event.target.closest(selector))
    if (!match) return

    gtag("event", match.eventName)
  }
}
