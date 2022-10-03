import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="new"
export default class extends Controller {
  static targets = ["nouveauContent", "openButton", "closeButton"]

  connect() {
    this.nouveauContentTarget.hidden = true
    this.closeButtonTarget.hidden = true
    console.log("hello from stiumuls controller")
  }

  openNouveau() {
    this.nouveauContentTarget.hidden = false
    this.openButtonTarget.hidden = true
    this.closeButtonTarget.hidden = false
  }

  closeNouveau() {
    this.nouveauContentTarget.hidden = true
    this.openButtonTarget.hidden = false
    this.closeButtonTarget.hidden = true
  }

}
