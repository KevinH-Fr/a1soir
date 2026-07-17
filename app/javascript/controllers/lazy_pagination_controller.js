import { Controller } from "@hotwired/stimulus"

// Précharge les turbo-frames lazy un peu avant qu'ils entrent dans la zone visible.
export default class extends Controller {
  static values = {
    rootMargin: { type: String, default: "0px 0px 800px 0px" },
  }

  connect() {
    if (this.element.getAttribute("loading") !== "lazy") return

    const scrollRoot = document.querySelector(".public-scroll")

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this.element.setAttribute("loading", "eager")
            this.observer.disconnect()
          }
        })
      },
      {
        root: scrollRoot,
        rootMargin: this.rootMarginValue,
        threshold: 0,
      }
    )

    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
