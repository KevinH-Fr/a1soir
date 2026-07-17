import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = {
    threshold: { type: Number, default: 400 },
  }

  connect() {
    this.scrollContainer = document.querySelector(".public-scroll")
    if (!this.scrollContainer) return

    this.onScroll = this.onScroll.bind(this)
    this.scrollContainer.addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    this.scrollContainer?.removeEventListener("scroll", this.onScroll)
  }

  onScroll() {
    const visible = this.scrollContainer.scrollTop > this.thresholdValue
    this.buttonTarget.classList.toggle("is-visible", visible)
  }

  scrollToTop() {
    this.scrollContainer?.scrollTo({ top: 0, behavior: "smooth" })
  }
}
