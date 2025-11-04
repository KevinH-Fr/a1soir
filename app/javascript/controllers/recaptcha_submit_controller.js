import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="recaptcha-submit"
export default class extends Controller {
  static targets = ["submitBtn", "warning", "recaptcha"]

  connect() {
    // Expose global callbacks expected by reCAPTCHA widget
    this.installGlobals()
    this.reset()
    // Debug: confirm controller connection and targets presence
    // eslint-disable-next-line no-console
    console.log('[recaptcha-submit] connected', {
      hasSubmitBtn: this.hasSubmitBtnTarget,
      hasWarning: this.hasWarningTarget,
      hasRecaptcha: this.hasRecaptchaTarget
    })
  }

  disconnect() {
    // Keep globals intact in case other instances exist; no-op
  }

  // Called when reCAPTCHA is solved
  onRecaptchaSuccess = () => {
    if (this.hasSubmitBtnTarget) {
      const b = this.submitBtnTarget
      b.disabled = false
      b.classList.remove("disabled", "btn-secondary")
      b.classList.add("btn-smoke-hover")
      b.innerHTML = '<i class="bi bi-send me-2"></i>Envoyer ma demande'
      b.style.opacity = "1"
      b.style.cursor = "pointer"
      b.removeAttribute("title")
    }
    if (this.hasWarningTarget) {
      this.warningTarget.style.display = "none"
    }
  }

  // Called when reCAPTCHA expires
  onRecaptchaExpired = () => {
    this.lock()
  }

  // Called on reCAPTCHA error
  onRecaptchaError = () => {
    this.lock()
  }

  // Click handler (bind in markup)
  trySubmit(event) {
    if (!this.hasSubmitBtnTarget) return
    if (this.submitBtnTarget.disabled) {
      event.preventDefault()
      event.stopPropagation()
      this.showWarning()
      this.scrollToRecaptcha()
    }
  }

  // Reset state on page loads
  reset() {
    if (!this.hasSubmitBtnTarget) return
    const b = this.submitBtnTarget
    b.disabled = true
    b.classList.remove("btn-smoke-hover")
    b.classList.add("disabled", "btn-secondary")
    b.innerHTML = '<i class="bi bi-lock me-2"></i>Validez d\'abord le reCAPTCHA'
    b.style.opacity = "0.6"
    b.style.cursor = "not-allowed"
    b.setAttribute("title", "Veuillez valider le reCAPTCHA")
    if (this.hasWarningTarget) this.warningTarget.style.display = "none"
  }

  // Helpers
  lock() {
    if (!this.hasSubmitBtnTarget) return
    const b = this.submitBtnTarget
    b.disabled = true
    b.classList.remove("btn-smoke-hover")
    b.classList.add("disabled", "btn-secondary")
    b.innerHTML = '<i class="bi bi-lock me-2"></i>Validez d\'abord le reCAPTCHA'
    b.style.opacity = "0.6"
    b.style.cursor = "not-allowed"
    b.setAttribute("title", "Veuillez valider le reCAPTCHA")
  }

  showWarning() {
    if (this.hasWarningTarget) {
      const w = this.warningTarget
      w.style.display = "flex"
      w.style.alignItems = "center"
      setTimeout(() => { w.style.display = "none" }, 3000)
    }
  }

  scrollToRecaptcha() {
    // Try target first, fallback to default widget class
    const el = this.hasRecaptchaTarget ? this.recaptchaTarget : document.querySelector('.g-recaptcha')
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'center' })
  }

  installGlobals() {
    // Install globals only once per page
    if (!window.onRecaptchaSuccess) {
      window.onRecaptchaSuccess = () => {
        const instance = this
        instance && instance.onRecaptchaSuccess()
      }
    }
    if (!window.onRecaptchaExpired) {
      window.onRecaptchaExpired = () => {
        const instance = this
        instance && instance.onRecaptchaExpired()
      }
    }
    if (!window.onRecaptchaError) {
      window.onRecaptchaError = () => {
        const instance = this
        instance && instance.onRecaptchaError()
      }
    }
  }
}


