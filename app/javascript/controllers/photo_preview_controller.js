import { Controller } from "@hotwired/stimulus"

const TYPES = ["image/jpeg", "image/jpg", "image/png", "image/webp"]

export default class extends Controller {
  static targets = ["image", "error", "card"]
  static values = {
    maxBytes: Number,
    maxEdge: Number,
    msgFormat: String,
    msgWeight: String,
    msgTooBig: String
  }

  connect() {
    if (this.hasImageTarget && this.imageTarget.getAttribute("src")) {
      this.markFilled(true)
    }
  }

  disconnect() {
    this.revoke()
  }

  preview(event) {
    const input = event.target
    const file = input.files?.[0]
    this.clearError()
    if (!file) {
      this.hidePreview()
      return
    }

    if (!TYPES.includes(file.type)) {
      this.reject(input, this.msgFormatValue)
      return
    }
    if (this.maxBytesValue > 0 && file.size > this.maxBytesValue) {
      this.reject(input, this.msgWeightValue)
      return
    }

    const url = URL.createObjectURL(file)
    const probe = new Image()
    probe.onload = () => {
      const longest = Math.max(probe.naturalWidth, probe.naturalHeight)
      if (this.maxEdgeValue > 0 && longest > this.maxEdgeValue) {
        URL.revokeObjectURL(url)
        this.reject(input, this.msgTooBigValue)
        return
      }
      this.showPreview(url)
    }
    probe.onerror = () => {
      URL.revokeObjectURL(url)
      this.reject(input, this.msgFormatValue)
    }
    probe.src = url
  }

  showPreview(url) {
    this.revoke()
    this.objectUrl = url
    if (!this.hasImageTarget) return
    this.imageTarget.src = url
    this.imageTarget.classList.remove("d-none")
    this.markFilled(true)
  }

  hidePreview() {
    this.revoke()
    if (this.hasImageTarget) {
      this.imageTarget.removeAttribute("src")
      this.imageTarget.classList.add("d-none")
    }
    this.markFilled(false)
  }

  markFilled(filled) {
    if (this.hasCardTarget) this.cardTarget.classList.toggle("is-filled", filled)
  }

  reject(input, message) {
    input.value = ""
    this.hidePreview()
    this.showError(message)
  }

  showError(message) {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("d-none")
  }

  clearError() {
    if (!this.hasErrorTarget) return
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("d-none")
  }

  revoke() {
    if (this.objectUrl) {
      URL.revokeObjectURL(this.objectUrl)
      this.objectUrl = null
    }
  }
}
