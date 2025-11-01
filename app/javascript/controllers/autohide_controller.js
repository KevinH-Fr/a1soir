import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autohide"
export default class extends Controller {
  static values = { delay: { type: Number, default: 4000 } }
  
  connect() {
    this.timeoutId = setTimeout(() => {
      this.dismiss()
    }, this.delayValue)
  }
  
  disconnect() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }
  
  dismiss() {
    this.element.remove()
  }
}
