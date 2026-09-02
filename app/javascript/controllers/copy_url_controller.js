import { Controller } from "@hotwired/stimulus"

// Copie une URL même hors contexte sécurisé (admin.lvh.me en http).
export default class extends Controller {
  static values = { text: String }
  static targets = ["label"]

  copy() {
    const text = this.textValue
    if (!text) return

    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(() => this.markCopied()).catch(() => this.copyFallback(text))
    } else {
      this.copyFallback(text)
    }
  }

  copyFallback(text) {
    const input = document.createElement("textarea")
    input.value = text
    input.setAttribute("readonly", "")
    input.style.position = "fixed"
    input.style.left = "-9999px"
    document.body.appendChild(input)
    input.select()
    try {
      document.execCommand("copy")
      this.markCopied()
    } finally {
      document.body.removeChild(input)
    }
  }

  markCopied() {
    if (!this.hasLabelTarget) return

    const original = this.labelTarget.dataset.originalLabel || this.labelTarget.textContent
    this.labelTarget.dataset.originalLabel = original
    this.labelTarget.textContent = "Copié"
    setTimeout(() => { this.labelTarget.textContent = original }, 2000)
  }
}
