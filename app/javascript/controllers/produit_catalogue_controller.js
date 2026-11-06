import { Controller } from "@hotwired/stimulus"

// Confirme le changement de catalogue sans soumettre le formulaire.
export default class extends Controller {
  static targets = ["option", "categories", "rubriques"]
  static values = {
    costume: { type: String, default: "costume_epoque_deguisements" },
    confirmCostume: String,
    confirmBoutique: String
  }

  connect() {
    const checked = this.optionTargets.find((input) => input.checked)
    this.current = checked ? checked.value : "tenues_mariage_soiree"
  }

  change(event) {
    const next = event.target.value
    if (next === this.current) return

    const message = next === this.costumeValue ? this.confirmCostumeValue : this.confirmBoutiqueValue
    if (!window.confirm(message)) {
      this.optionTargets.forEach((input) => {
        input.checked = input.value === this.current
      })
      return
    }

    this.current = next
    const costume = next === this.costumeValue
    this.categoriesTarget.hidden = costume
    this.rubriquesTarget.hidden = !costume
  }
}
