import { Controller } from "@hotwired/stimulus"

const TYPES = ["image/jpeg", "image/jpg", "image/png", "image/webp"]

export default class extends Controller {
  static targets = ["image", "error"]
  static values = {
    maxBytes: Number,
    maxEdge: Number,
    minEdge: Number,
    msgFormat: String,
    msgWeight: String,
    msgTooBig: String,
    msgTooSmall: String
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
    if (file.size > this.maxBytesValue) {
      this.reject(input, this.msgWeightValue)
      return
    }

    const url = URL.createObjectURL(file)
    const probe = new Image()
    probe.onload = () => {
      const longest = Math.max(probe.naturalWidth, probe.naturalHeight)
      const shortest = Math.min(probe.naturalWidth, probe.naturalHeight)
      if (longest > this.maxEdgeValue) {
        URL.revokeObjectURL(url)
        this.reject(input, this.msgTooBigValue)
        return
      }
      if (shortest < this.minEdgeValue) {
        URL.revokeObjectURL(url)
        this.reject(input, this.msgTooSmallValue)
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
  }

  hidePreview() {
    this.revoke()
    if (!this.hasImageTarget) return
    this.imageTarget.removeAttribute("src")
    this.imageTarget.classList.add("d-none")
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
