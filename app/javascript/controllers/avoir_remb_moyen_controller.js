import { Controller } from "@hotwired/stimulus"

// Affiche le select moyen uniquement pour type "remboursement".
export default class extends Controller {
  static targets = ["typeSelect", "moyenField", "moyenSelect"]
  static values = { requireMoyenOnCreate: Boolean }

  connect() {
    this.sync()
  }

  sync() {
    const isRemboursement = this.typeSelectTarget.value === "remboursement"
    this.moyenFieldTarget.hidden = !isRemboursement

    if (!isRemboursement) {
      this.moyenSelectTarget.value = ""
      this.moyenSelectTarget.required = false
    } else {
      this.moyenSelectTarget.required = this.requireMoyenOnCreateValue
    }
  }
}
