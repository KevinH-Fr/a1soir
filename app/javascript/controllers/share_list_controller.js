import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["whatsapp", "email", "native", "copy"]
  static values  = { title: String, items: Array, copied: String, copiedShort: String }

  connect() {
    if (navigator.share) {
      this.nativeTargets.forEach(el => el.classList.remove("d-none"))
    } else {
      this.whatsappTargets.forEach(el => el.classList.remove("d-none"))
      this.emailTargets.forEach(el => el.classList.remove("d-none"))
    }
  }

  shareWhatsapp(event) {
    event.preventDefault()
    const text = this.#buildText()
    window.open(`https://wa.me/?text=${encodeURIComponent(text)}`, "_blank", "noopener,noreferrer")
  }

  shareEmail(event) {
    event.preventDefault()
    const text = this.#buildText()
    window.location.href = `mailto:?subject=${encodeURIComponent(this.titleValue)}&body=${encodeURIComponent(text)}`
  }

  shareNative(event) {
    event.preventDefault()
    // Pas de `url` : sinon on partage aussi l’URL de la page courante (ex. panier)
    // alors que le texte contient déjà les liens produits (#buildText).
    navigator.share({
      title: this.titleValue,
      text: this.#buildText()
    }).catch(() => {})
  }

  copyToClipboard(event) {
    event.preventDefault()
    const text = this.#buildText()
    navigator.clipboard.writeText(text).then(() => {
      this.copyTargets.forEach(btn => this.#flashCopied(btn))
      this.#showToast(this.copiedValue)
    }).catch(() => {})
  }

  #buildText() {
    const lines = this.itemsValue.map(item => {
      const price = item.price ? ` — ${item.price}` : ""
      return `• ${item.name}${price}\n  ${item.url}`
    })
    return `${this.titleValue} :\n\n${lines.join("\n")}`
  }

  #showToast(message) {
    const id = `flash_success_${Date.now()}`
    const el = document.createElement("div")
    el.className = "alert alert-cabine alert-dismissible fade show position-fixed"
    el.setAttribute("role", "alert")
    el.setAttribute("id", id)
    el.setAttribute("style", "bottom: 20px; right: 20px; z-index: 2000; min-width: 300px; max-width: 500px;")
    el.setAttribute("data-controller", "autohide")
    el.setAttribute("data-autohide-delay-value", "3000")
    el.innerHTML = `
      <i class="bi bi-clipboard-check me-2"></i>${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `
    document.body.appendChild(el)
  }

  #flashCopied(btn) {
    const icon = btn.querySelector("i")
    const label = btn.querySelector("span")
    const originalLabel = label?.textContent
    const originalIcon = icon?.className

    if (icon) icon.className = "bi bi-clipboard-check"
    if (label) label.textContent = this.copiedShortValue || "✓"

    setTimeout(() => {
      if (icon) icon.className = originalIcon
      if (label) label.textContent = originalLabel
    }, 2000)
  }
}
