import { Controller } from "@hotwired/stimulus"

// Desktop  : mouseenter/mouseleave → stagger subtitle, tags, cta
// Mobile   : IntersectionObserver  → stagger title + all reveal content on scroll
export default class extends Controller {
  static targets = ["title", "subtitle", "tags", "cta"]
  static values = {
    baseDelay: { type: Number, default: 600 },
    delay:     { type: Number, default: 150 },
    tagDelay:  { type: Number, default: 55 }
  }

  connect() {
    this.timers = []

    if (window.matchMedia("(pointer: coarse)").matches) {
      this.hideAll()
      this.setupObserver()
    } else {
      this.hideReveal()
      this.setupHover()
    }
  }

  // ── Accessors ───────────────────────────────────────────────────────────────

  get tagElements() {
    return this.hasTagsTarget
      ? Array.from(this.tagsTarget.querySelectorAll(".cc-tag"))
      : []
  }

  // ── Low-level helpers ───────────────────────────────────────────────────────

  hide(el, transform = "translateY(20px)") {
    if (!el) return
    el.style.opacity    = "0"
    el.style.transform  = transform
    el.style.transition = "opacity 0.5s ease, transform 0.5s ease"
  }

  hideTag(el) {
    el.style.opacity    = "0"
    el.style.transform  = "translateY(12px) scale(0.82)"
    el.style.transition = "opacity 0.4s ease, transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)"
  }

  show(el, delay = 0) {
    if (!el) return
    this.timers.push(setTimeout(() => {
      el.style.opacity   = "1"
      el.style.transform = "translateY(0)"
    }, delay))
  }

  showTag(el, delay = 0) {
    this.timers.push(setTimeout(() => {
      el.style.opacity   = "1"
      el.style.transform = "translateY(0) scale(1)"
    }, delay))
  }

  clearTimers() {
    this.timers.forEach(t => clearTimeout(t))
    this.timers = []
  }

  // ── Hide groups ─────────────────────────────────────────────────────────────

  hideAll() {
    this.clearTimers()
    this.hide(this.hasTitleTarget    ? this.titleTarget    : null, "translateY(30px)")
    this.hide(this.hasSubtitleTarget ? this.subtitleTarget : null, "translateY(20px)")
    this.tagElements.forEach(tag => this.hideTag(tag))
    this.hide(this.hasCtaTarget      ? this.ctaTarget      : null, "translateY(20px)")
  }

  hideReveal() {
    this.clearTimers()
    this.hide(this.hasSubtitleTarget ? this.subtitleTarget : null, "translateY(1.5rem)")
    this.tagElements.forEach(tag => this.hideTag(tag))
    this.hide(this.hasCtaTarget      ? this.ctaTarget      : null, "translateY(1.5rem)")
  }

  // ── Show groups ─────────────────────────────────────────────────────────────

  showAll() {
    const b = this.baseDelayValue, d = this.delayValue, td = this.tagDelayValue
    this.show(this.hasTitleTarget    ? this.titleTarget    : null, b)
    this.show(this.hasSubtitleTarget ? this.subtitleTarget : null, b + d)
    this.tagElements.forEach((tag, i) => this.showTag(tag, b + d * 2 + i * td))
    this.show(this.hasCtaTarget ? this.ctaTarget : null, b + d * 2 + this.tagElements.length * td + 60)
  }

  showReveal(base = 0) {
    const d = this.delayValue, td = this.tagDelayValue
    this.show(this.hasSubtitleTarget ? this.subtitleTarget : null, base)
    this.tagElements.forEach((tag, i) => this.showTag(tag, base + d + i * td))
    this.show(this.hasCtaTarget ? this.ctaTarget : null, base + d + this.tagElements.length * td + 40)
  }

  // ── Setup ────────────────────────────────────────────────────────────────────

  setupHover() {
    this.onEnter = () => { this.clearTimers(); this.showReveal(0) }
    this.onLeave = () => { this.hideReveal() }
    this.element.addEventListener("mouseenter", this.onEnter)
    this.element.addEventListener("mouseleave", this.onLeave)
  }

  setupObserver() {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) { this.showAll() } else { this.hideAll() }
        })
      },
      { root: null, rootMargin: "0px", threshold: 0.1 }
    )
    this.observer.observe(this.element)
  }

  disconnect() {
    this.clearTimers()
    if (this.observer) this.observer.disconnect()
    if (this.onEnter) {
      this.element.removeEventListener("mouseenter", this.onEnter)
      this.element.removeEventListener("mouseleave", this.onLeave)
    }
  }
}
