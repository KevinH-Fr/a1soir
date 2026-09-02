import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "showLabel", "hideLabel"]

  toggle(event) {
    const hidden = this.panelTarget.classList.toggle("d-none")
    if (this.hasShowLabelTarget) this.showLabelTarget.classList.toggle("d-none", !hidden)
    if (this.hasHideLabelTarget) this.hideLabelTarget.classList.toggle("d-none", hidden)
    event.currentTarget.setAttribute("aria-expanded", hidden ? "false" : "true")
  }
}
