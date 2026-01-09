// app/javascript/controllers/scroll_reveal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("ScrollRevealController connected")
    this.setupIntersectionObserver()
  }

  setupIntersectionObserver() {
    const options = {
      root: null,
      rootMargin: "0px 0px -50px 0px",
      threshold: 0.1
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-revealed")
        }
      })
    }, options)

    // Observer tous les éléments avec data-scroll-reveal
    const elements = document.querySelectorAll("[data-scroll-reveal]")
    
    elements.forEach(element => {
      this.observer.observe(element)
    })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}

