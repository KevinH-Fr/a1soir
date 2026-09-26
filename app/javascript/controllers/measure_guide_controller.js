import { Controller } from "@hotwired/stimulus"
import { resolveClip, preloadUrls } from "../mensuration/figure_assets"
import {
  fetchSvg,
  buildViewSvg,
  normalizeGuides
} from "../mensuration/figure_render"

const REDUCED = window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches
const GUIDE_DASH = 3
const GUIDE_GAP = 3.5
const GUIDE_REPLAY_PAUSE = 4
const GUIDE_DRAW_SPEED = 250
const GUIDE_DRAW_MIN = 0.9

function reportFieldValidity(root) {
  for (const input of root.querySelectorAll("input, select, textarea")) {
    if (input.disabled) continue
    if (!input.checkValidity()) {
      input.reportValidity()
      return false
    }
  }
  return true
}

export default class extends Controller {
  static targets = ["field", "figure", "canvas", "title", "howto"]
  static values = {
    index: { type: Number, default: 0 },
    template: { type: String, default: "femme" }
  }

  connect() {
    this.currentView = null
    this.loadToken = 0
    this.animToken = 0
    this.drawTimers = []
    this.drawAnims = []
    const views = [...new Set(
      this.fieldTargets
        .map((el) => resolveClip(el.dataset.clip, this.templateValue)?.view)
        .filter(Boolean)
    )]
    preloadUrls(this.templateValue, views).forEach((url) => {
      fetchSvg(url).catch(() => {})
    })
    this.showField()
  }

  get atFirst() {
    return this.indexValue <= 0
  }

  get atLast() {
    return this.indexValue >= this.fieldTargets.length - 1
  }

  get figureVisible() {
    return Boolean(this.fieldTargets[this.indexValue]?.dataset.clip)
  }

  enterFromStart() {
    this.indexValue = 0
    this.showField()
  }

  enterFromEnd() {
    this.indexValue = Math.max(this.fieldTargets.length - 1, 0)
    this.showField()
  }

  nextField() {
    if (this.atLast) return
    this.indexValue++
    this.showField()
  }

  prevField() {
    if (this.atFirst) return
    this.indexValue--
    this.showField()
  }

  validateCurrent() {
    const field = this.fieldTargets[this.indexValue]
    if (!field) return true
    return reportFieldValidity(field)
  }

  currentFieldRoot() {
    return this.fieldTargets[this.indexValue]
  }

  showField() {
    this.fieldTargets.forEach((field, i) => {
      field.classList.toggle("d-none", i !== this.indexValue)
      if (i === this.indexValue) this.restoreFieldValues(field)
    })
    this.syncCaption()
    this.highlight()
  }

  restoreFieldValues(field) {
    if (!field) return

    field.querySelectorAll("input, textarea, select").forEach((el) => {
      const saved = el.dataset.initialValue
      if (saved == null || saved === "") return
      if (el.tagName === "SELECT") {
        if (!el.value) el.value = saved
      } else if (!el.value?.trim()) {
        el.value = saved
      }
    })
  }

  stashFieldValues() {
    this.fieldTargets.forEach((field) => {
      field.querySelectorAll("input, textarea, select").forEach((el) => {
        if (!el.name) return
        if (el.value) el.dataset.initialValue = el.value
      })
    })
  }

  syncCaption() {
    const field = this.fieldTargets[this.indexValue]
    const title = field?.dataset.title || ""
    const howto = field?.dataset.howto || ""

    if (this.hasTitleTarget) this.titleTarget.textContent = title
    if (this.hasHowtoTarget) {
      this.howtoTarget.textContent = howto
      this.howtoTarget.classList.toggle("d-none", !howto)
    }
    this.element.classList.toggle("mensuration-guide--howto", Boolean(howto))
  }

  highlight() {
    const clip = this.fieldTargets[this.indexValue]?.dataset.clip
    this.element.classList.toggle("mensuration-guide--plain", !clip)
    if (this.hasFigureTarget) this.figureTarget.classList.toggle("d-none", !clip)
    this.syncGuidedShell(Boolean(clip))
    this.paintMeasure(clip)
  }

  // Le form-wizard connect avant measure-guide : sans ça, --guided manque au refresh
  // et le h2 d'étape (« Vos mensurations ») reste visible au-dessus de la figure.
  syncGuidedShell(guided) {
    const step = this.element.closest('[data-form-wizard-target="step"]')
    if (step?.classList.contains("d-none")) return

    document.querySelector("[data-mensuration-shell]")?.classList.toggle(
      "mensuration-shell--guided",
      guided
    )
  }

  async paintMeasure(clip) {
    if (!this.hasCanvasTarget) return

    const spec = resolveClip(clip, this.templateValue)
    if (!spec) {
      this.clearActive()
      this.canvasTarget.classList.remove("is-view-swap")
      this.canvasTarget.replaceChildren()
      this.currentView = null
      return
    }

    const token = ++this.loadToken
    try {
      await this.ensureView(spec, token)
      if (token !== this.loadToken) return
      this.activateMeasure(spec.id)
    } catch (error) {
      if (token === this.loadToken) {
        console.warn("[measure-guide] SVG load failed", spec.url, error)
      }
    }
  }

  async ensureView(spec, token = this.loadToken) {
    if (this.currentView === spec.view && this.canvasTarget.querySelector("svg.mensuration-figure-svg")) {
      return
    }

    const svg = await fetchSvg(spec.url)
    if (token !== this.loadToken) return
    if (!svg) throw new Error("empty svg")

    const clone = buildViewSvg(svg, spec.viewBox)
    normalizeGuides(clone, this.templateValue)

    const hasCurrent = Boolean(this.canvasTarget.querySelector("svg.mensuration-figure-svg"))
    const animate = hasCurrent && !REDUCED

    if (animate) {
      this.canvasTarget.classList.add("is-view-swap")
      await this.waitMs(180)
      if (token !== this.loadToken) return
    }

    this.clearActive()
    this.canvasTarget.replaceChildren(clone)
    this.currentView = spec.view

    if (animate) {
      void this.canvasTarget.offsetWidth
      this.canvasTarget.classList.remove("is-view-swap")
      await this.waitMs(160)
      if (token !== this.loadToken) return
    } else {
      this.canvasTarget.classList.remove("is-view-swap")
    }
  }

  waitMs(ms) {
    return new Promise((resolve) => {
      window.setTimeout(resolve, ms)
    })
  }

  clearActive() {
    this.animToken++
    this.drawTimers.forEach((id) => window.clearTimeout(id))
    this.drawTimers = []
    this.drawAnims.forEach((anim) => anim.cancel())
    this.drawAnims = []

    this.canvasTarget.querySelectorAll(".measurement.is-active").forEach((el) => {
      el.classList.remove("is-active", "is-animating", "is-drawing", "is-settled")
      el.querySelectorAll(".guide-arrow, .helper").forEach((guide) => {
        guide.style.strokeDasharray = ""
        guide.style.strokeDashoffset = ""
        guide.style.transition = ""
        guide.style.opacity = ""
      })
    })
  }

  activateMeasure(id) {
    this.clearActive()
    const node = this.canvasTarget.querySelector(`#${CSS.escape(id)}`)
    if (!node) return

    node.classList.add("is-active")
    if (REDUCED) {
      node.classList.add("is-animating", "is-settled")
      return
    }

    this.playGuideAnimation(node)
  }

  guideLength(el) {
    if (typeof el.getTotalLength === "function") {
      try {
        const n = el.getTotalLength()
        if (Number.isFinite(n) && n > 0) return n
      } catch (_) { /* line/path not rendered yet */ }
    }
    if (el.localName === "line") {
      const x1 = Number(el.getAttribute("x1"))
      const y1 = Number(el.getAttribute("y1"))
      const x2 = Number(el.getAttribute("x2"))
      const y2 = Number(el.getAttribute("y2"))
      const n = Math.hypot(x2 - x1, y2 - y1)
      if (Number.isFinite(n) && n > 0) return n
    }
    return 80
  }

  dashedDrawPattern(length, sparse = false) {
    const dash = sparse ? 2.2 : GUIDE_DASH
    const gap = sparse ? 5.2 : GUIDE_GAP
    const pair = dash + gap
    const repeats = Math.ceil(length / pair) + 2
    const dots = Array.from({ length: repeats }, () => `${dash} ${gap}`).join(" ")
    return `${dots} 0 ${length}`
  }

  drawDuration(length) {
    return Math.max(GUIDE_DRAW_MIN, length / GUIDE_DRAW_SPEED)
  }

  playStroke(guide, length, duration) {
    guide.style.transition = "none"
    const anim = guide.animate(
      [{ strokeDashoffset: String(length) }, { strokeDashoffset: "0" }],
      {
        duration: duration * 1000,
        easing: "cubic-bezier(0.42, 0, 1, 1)",
        fill: "forwards"
      }
    )
    this.drawAnims.push(anim)
    return anim.finished.catch(() => {})
  }

  playGuideAnimation(node) {
    const helpers = [...node.querySelectorAll(".helper")]
    const arrows = [...node.querySelectorAll(".guide-arrow")]
    const drawn = arrows.length ? arrows : helpers
    if (!drawn.length) {
      node.classList.add("is-animating")
      return
    }

    const token = ++this.animToken
    this.drawAnims.forEach((anim) => anim.cancel())
    this.drawAnims = []
    const lengths = drawn.map((guide) => this.guideLength(guide))

    drawn.forEach((guide, i) => {
      const sparse = guide.classList.contains("guide-arrow--back")
      guide.style.strokeDasharray = this.dashedDrawPattern(lengths[i], sparse)
      guide.style.strokeDashoffset = `${lengths[i]}`
      guide.style.transition = "none"
    })

    helpers.forEach((helper) => {
      if (drawn.includes(helper)) return
      helper.style.opacity = "0"
      helper.style.transition = "none"
    })

    void node.getBoundingClientRect()
    node.classList.add("is-animating", "is-drawing")
    node.classList.remove("is-settled")

    requestAnimationFrame(() => {
      if (token !== this.animToken) return

      const waits = drawn.map((guide, i) => (
        this.playStroke(guide, lengths[i], this.drawDuration(lengths[i]))
      ))

      const maxDuration = Math.max(...lengths.map((length) => this.drawDuration(length)))
      const helperFade = Math.min(0.55, maxDuration * 0.28)
      const helperDelay = maxDuration * 0.42
      helpers.forEach((helper) => {
        if (drawn.includes(helper)) return
        helper.style.transition = `opacity ${helperFade}s ease ${helperDelay}s`
        helper.style.opacity = ""
      })

      Promise.all(waits).then(() => {
        if (token !== this.animToken || !node.isConnected) return
        node.classList.remove("is-drawing")
        node.classList.add("is-settled")

        this.drawTimers.push(window.setTimeout(() => {
          if (token !== this.animToken || !node.isConnected) return
          this.playGuideAnimation(node)
        }, GUIDE_REPLAY_PAUSE * 1000))
      })
    })
  }

  disconnect() {
    this.animToken++
    this.drawTimers.forEach((id) => window.clearTimeout(id))
    this.drawTimers = []
    this.drawAnims.forEach((anim) => anim.cancel())
    this.drawAnims = []
    const step = this.element.closest('[data-form-wizard-target="step"]')
    if (step?.classList.contains("d-none")) return
    this.syncGuidedShell(false)
  }
}
