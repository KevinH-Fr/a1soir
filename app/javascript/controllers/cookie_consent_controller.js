import { Controller } from "@hotwired/stimulus"

// Gère le consentement aux cookies de mesure d'audience (GA4)
// Utilise un cookie "analytics_consent" avec les valeurs :
// - "yes" : consentement donné
// - "no"  : refus
// Aucune valeur => bannière affichée

export default class extends Controller {
  static targets = ["banner"]

  connect() {
    const consent = this.getCookie("analytics_consent")

    if (!consent) {
      // Aucun choix : on affiche la bannière
      this.showBanner()
    }
  }

  accept() {
    this.setCookie("analytics_consent", "yes", 395) // ~13 mois
    // On recharge pour que le layout voie le cookie et rende GA4
    window.location.reload()
  }

  refuse() {
    this.setCookie("analytics_consent", "no", 395)
    this.hideBanner()
  }

  reset() {
    // Permet de réinitialiser le choix (lien « Gérer mes cookies »)
    this.setCookie("analytics_consent", "", -1) // expire immédiatement
    this.showBanner()
  }

  showBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove("d-none")
    }
  }

  hideBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.add("d-none")
    }
  }

  getCookie(name) {
    const value = `; ${document.cookie}`
    const parts = value.split(`; ${name}=`)
    if (parts.length === 2) return parts.pop().split(";").shift()
    return null
  }

  setCookie(name, value, days) {
    const date = new Date()
    date.setTime(date.getTime() + days * 24 * 60 * 60 * 1000)
    const expires = `expires=${date.toUTCString()}`
    document.cookie = `${name}=${value}; ${expires}; path=/`
  }
}

