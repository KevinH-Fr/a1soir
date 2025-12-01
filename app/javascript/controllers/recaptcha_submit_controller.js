import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitBtn"]

  connect() {
    this.installGlobals()
    this.disableButton()
  }

  disconnect() {
    if (window.recaptchaSubmitController === this) {
      window.recaptchaSubmitController = null
      window.onRecaptchaSuccess = null
      window.onRecaptchaExpired = null
      window.onRecaptchaError = null
    }
  }

  // Callbacks reCAPTCHA (appelés par la gem recaptcha)
  onRecaptchaSuccess = () => {
    this.enableButton()
  }

  onRecaptchaExpired = () => {
    this.disableButton()
  }

  onRecaptchaError = () => {
    this.disableButton()
  }

  // Activer le bouton
  enableButton() {
    if (this.hasSubmitBtnTarget) {
      const btn = this.submitBtnTarget
      btn.disabled = false
      btn.classList.remove("disabled")
      btn.innerHTML = '<i class="bi bi-send me-2"></i>Envoyer ma demande'
      btn.style.opacity = "1"
      btn.style.cursor = "pointer"
    }
  }

  // Désactiver le bouton
  disableButton() {
    if (this.hasSubmitBtnTarget) {
      const btn = this.submitBtnTarget
      btn.disabled = true
      btn.classList.add("disabled")
      btn.style.opacity = "0.6"
      btn.style.cursor = "not-allowed"
    }
  }

  // Installer les callbacks globaux pour reCAPTCHA
  installGlobals() {
    window.recaptchaSubmitController = this
    window.onRecaptchaSuccess = () => {
      window.recaptchaSubmitController?.onRecaptchaSuccess()
    }
    window.onRecaptchaExpired = () => {
      window.recaptchaSubmitController?.onRecaptchaExpired()
    }
    window.onRecaptchaError = () => {
      window.recaptchaSubmitController?.onRecaptchaError()
    }
  }
}


