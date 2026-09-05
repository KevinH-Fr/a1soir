import { Controller } from "@hotwired/stimulus"

// Landing /mensurations : captcha visible dès le départ, verrouillé tant que l'e-mail est vide.
export default class extends Controller {
  static targets = ["locale", "email", "captcha", "captchaSection", "submit"]

  connect() {
    this.widgetId = null
    this.renderCaptcha()
    this.syncFromEmail()
  }

  disconnect() {
    if (this.captchaWait) window.clearInterval(this.captchaWait)
  }

  emailChanged() {
    this.syncFromEmail()
  }

  guard(event) {
    if (this.emailFilled() && this.hasToken()) return

    event.preventDefault()
    this.lockSubmit()
  }

  syncFromEmail() {
    if (!this.emailFilled()) {
      this.resetCaptcha()
      this.lockCaptcha()
      this.lockSubmit()
      return
    }

    this.unlockCaptcha()
    if (this.hasToken()) this.unlockSubmit()
    else this.lockSubmit()
  }

  emailFilled() {
    return this.emailTarget.value.trim() !== "" && this.emailTarget.checkValidity()
  }

  hasToken() {
    return this.widgetId != null && Boolean(window.grecaptcha?.getResponse(this.widgetId))
  }

  lockCaptcha() {
    this.captchaSectionTarget.classList.add("is-locked")
  }

  unlockCaptcha() {
    this.captchaSectionTarget.classList.remove("is-locked")
  }

  renderCaptcha() {
    if (this.widgetId != null || this.captchaWait) return

    const sitekey = this.captchaTarget.dataset.sitekey
    if (!sitekey) return

    const tryRender = () => {
      if (this.widgetId != null) return true
      if (!window.grecaptcha?.render) return false

      this.widgetId = window.grecaptcha.render(this.captchaTarget, {
        sitekey,
        hl: this.hasLocaleTarget ? this.localeTarget.value || "fr" : "fr",
        callback: () => this.onCaptchaSuccess(),
        "expired-callback": () => this.onCaptchaExpired(),
        "error-callback": () => this.onCaptchaExpired()
      })
      return true
    }

    if (tryRender()) return

    this.captchaWait = window.setInterval(() => {
      if (tryRender()) {
        window.clearInterval(this.captchaWait)
        this.captchaWait = null
      }
    }, 200)
  }

  resetCaptcha() {
    if (this.widgetId == null || !window.grecaptcha?.reset) return
    if (!window.grecaptcha.getResponse(this.widgetId)) return

    window.grecaptcha.reset(this.widgetId)
  }

  onCaptchaSuccess() {
    if (!this.emailFilled()) {
      this.resetCaptcha()
      this.lockSubmit()
      return
    }
    this.unlockSubmit()
  }

  onCaptchaExpired() {
    this.lockSubmit()
  }

  unlockSubmit() {
    this.submitTarget.classList.remove("is-pending")
    this.submitTarget.disabled = false
  }

  lockSubmit() {
    this.submitTarget.classList.add("is-pending")
    this.submitTarget.disabled = true
  }
}
