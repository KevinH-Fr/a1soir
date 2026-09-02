import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { length: { type: Number, default: 6 } }

  connect() {
    this.submitted = false
  }

  check() {
    this.element.value = this.element.value.replace(/\D/g, "").slice(0, this.lengthValue)
    if (this.submitted || this.element.value.length !== this.lengthValue) return

    this.submitted = true
    this.element.form?.requestSubmit()
  }
}
