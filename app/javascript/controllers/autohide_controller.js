import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autohide"
export default class extends Controller {
  connect() {
    setTimeout(() => {
      this.dismiss()
    }, 4000)
  }
  dismiss() {
  //  console.log("call dismiss auto hide")
    this.element.remove()
  }
}
