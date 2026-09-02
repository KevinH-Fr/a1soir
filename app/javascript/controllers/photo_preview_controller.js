import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image"]

  preview(event) {
    const file = event.target.files?.[0]
    if (!file || !this.hasImageTarget) return

    this.imageTarget.src = URL.createObjectURL(file)
    this.imageTarget.classList.remove("d-none")
  }
}
