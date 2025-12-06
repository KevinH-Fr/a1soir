import { Controller } from "@hotwired/stimulus"

// Contrôleur pour bloquer le scroll du body quand la modale gallery s'ouvre
export default class extends Controller {
  connect() {
    this.scrollY = 0
    
    this.element.addEventListener('show.bs.modal', this.handleModalShow.bind(this))
    this.element.addEventListener('hide.bs.modal', this.handleModalHide.bind(this))
  }

  disconnect() {
    // Nettoyer les styles si le contrôleur est déconnecté
    document.body.style.overflow = ''
    document.body.style.position = ''
    document.body.style.top = ''
    document.body.style.width = ''
  }

  handleModalShow() {
    this.scrollY = window.scrollY
    document.body.style.overflow = 'hidden'
    document.body.style.position = 'fixed'
    document.body.style.top = `-${this.scrollY}px`
    document.body.style.width = '100%'
  }

  handleModalHide() {
    document.body.style.overflow = ''
    document.body.style.position = ''
    document.body.style.top = ''
    document.body.style.width = ''
    window.scrollTo(0, this.scrollY)
  }
}

