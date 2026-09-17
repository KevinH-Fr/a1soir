import { Controller } from "@hotwired/stimulus"

// Saisie OTP moderne : 6 cases chiffres, collage, autofill, envoi auto.
export default class extends Controller {
  static targets = ["digit", "hidden"]
  static values = { length: { type: Number, default: 6 } }

  connect() {
    this.submitted = false
  }

  input(event) {
    const input = event.target
    const index = this.digitTargets.indexOf(input)
    if (index < 0) return

    const raw = input.value.replace(/\D/g, "")
    if (raw.length > 1) {
      this.fillFrom(raw, index)
      this.syncAndMaybeSubmit()
      return
    }

    input.value = raw.slice(0, 1)
    if (raw && index < this.digitTargets.length - 1) {
      this.focusDigit(index + 1)
    }
    this.syncAndMaybeSubmit()
  }

  keydown(event) {
    const index = this.digitTargets.indexOf(event.target)
    if (index < 0) return

    if (event.key === "Backspace") {
      if (event.target.value) {
        event.target.value = ""
        this.sync()
        return
      }
      if (index > 0) {
        event.preventDefault()
        this.digitTargets[index - 1].value = ""
        this.focusDigit(index - 1)
        this.sync()
      }
      return
    }

    if (event.key === "ArrowLeft" && index > 0) {
      event.preventDefault()
      this.focusDigit(index - 1)
    } else if (event.key === "ArrowRight" && index < this.digitTargets.length - 1) {
      event.preventDefault()
      this.focusDigit(index + 1)
    }
  }

  paste(event) {
    event.preventDefault()
    const text = (event.clipboardData || window.clipboardData)?.getData("text") || ""
    const index = this.digitTargets.indexOf(event.target)
    this.fillFrom(text, index > 0 ? index : 0)
    this.syncAndMaybeSubmit()
  }

  fillFrom(value, startIndex = 0) {
    const chars = value.replace(/\D/g, "").slice(0, this.lengthValue - startIndex).split("")
    chars.forEach((char, offset) => {
      const el = this.digitTargets[startIndex + offset]
      if (el) el.value = char
    })
    const focusAt = Math.min(startIndex + chars.length, this.digitTargets.length - 1)
    this.focusDigit(focusAt)
  }

  focusDigit(index) {
    const el = this.digitTargets[index]
    if (!el) return
    el.focus()
    el.select()
  }

  code() {
    return this.digitTargets.map((d) => d.value).join("")
  }

  sync() {
    if (this.hasHiddenTarget) this.hiddenTarget.value = this.code()
  }

  syncAndMaybeSubmit() {
    this.sync()
    if (this.submitted || this.code().length !== this.lengthValue) return

    this.submitted = true
    this.element.requestSubmit()
  }

  // Avant envoi manuel (bouton Valider) : resynchronise les 6 cases → champ code.
  prepareSubmit(event) {
    this.sync()
    if (this.code().length === this.lengthValue) return

    event.preventDefault()
    const firstEmpty = this.digitTargets.find((d) => !d.value) || this.digitTargets[0]
    firstEmpty?.focus()
  }
}
