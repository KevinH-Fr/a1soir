import { Controller } from "@hotwired/stimulus"

// Dev only : préremplit les champs du formulaire courant.
export default class extends Controller {
  fill(event) {
    event.preventDefault()
    const form = this.element.closest("form")
    if (!form) return

    form.querySelectorAll("input, select, textarea").forEach((el) => this.fillControl(el))
  }

  fillControl(el) {
    if (el.disabled || el.type === "hidden" || el.type === "file" || el.type === "submit" || el.type === "button") return

    const name = el.name || ""

    if (el.type === "date") {
      el.value = "2026-12-15"
    } else if (el.tagName === "SELECT") {
      const option = [...el.options].find((o) => o.value)
      if (option) el.value = option.value
    } else if (el.tagName === "TEXTAREA") {
      el.value = "Près du corps, manches courtes"
    } else if (el.type === "tel" || name.includes("[telephone]")) {
      el.value = "0612345678"
    } else if (name.includes("[prenom]")) {
      el.value = "Anna"
    } else if (name.includes("[nom]")) {
      el.value = "Durand"
    } else if (name.includes("[adresse]")) {
      el.value = "27 Boulevard Carnot"
    } else if (name.includes("[cp]")) {
      el.value = "06400"
    } else if (name.includes("[ville]")) {
      el.value = "Cannes"
    } else if (name.includes("hauteur_talons")) {
      el.value = "8"
    } else if (name.includes("[hauteur]") || name.includes("hauteur")) {
      el.value = "168"
    } else if (name.includes("pointure")) {
      el.value = "39"
    } else if (name.includes("tour_") || name.includes("largeur") || name.includes("longueur")) {
      el.value = "90"
    } else {
      el.value = "40"
    }

    el.dispatchEvent(new Event("input", { bubbles: true }))
    el.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
