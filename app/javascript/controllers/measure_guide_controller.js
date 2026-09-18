import { Controller } from "@hotwired/stimulus"
import { resolveClip, preloadUrls } from "../mensuration/figure_assets"

const NS = "http://www.w3.org/2000/svg"
const XLINK = "http://www.w3.org/1999/xlink"
const REDUCED = window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches
const GUIDE_DASH = 3
const GUIDE_GAP = 3.5
const GUIDE_REPLAY_PAUSE = 4
const GUIDE_DRAW_SPEED = 250
const GUIDE_DRAW_MIN = 0.9
const GUIDE_END_R = 4.4

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
// Recalage visuel sur la planche 1122×1402 (ellipse → cx/cy/rx ; ligne → x/y).
const GUIDE_TWEAKS = {
  femme: {
    "measure-neck": { cx: 232, cy: 258, rx: 42 },
    "measure-bust": { cx: 230, cy: 392, rx: 105 },
    "measure-underbust": { cx: 230, cy: 438, rx: 88 },
    "measure-waist": { cx: 230, cy: 548, rx: 92 },
    "measure-hips": { cx: 232, cy: 668, rx: 122 },
    "measure-thigh": { cx: 174, cy: 778, rx: 46 },
    "measure-height": { x1: 678, x2: 678, y1: 50, y2: 1300 },
    "measure-outside-leg": { x1: 546, x2: 546, y1: 590, y2: 1268 },
    "measure-inside-leg": { x1: 225, x2: 205, y1: 705, y2: 1265 },
    "measure-shoulders": { x1: 783, x2: 1045, y1: 302, y2: 302 },
    "measure-belt-waist": { cx: 913, cy: 576, rx: 82 },
    "measure-arm-length": { d: "M540 302 L618 704" }
  },
  homme: {
    "measure-neck": { cx: 226, cy: 248, rx: 38 },
    "measure-chest": { cx: 226, cy: 370, rx: 105 },
    "measure-waist": { cx: 226, cy: 530, rx: 90 },
    "measure-hips": { cx: 220, cy: 638, rx: 108 },
    "measure-thigh": { cx: 164, cy: 768, rx: 48 },
    "measure-height": { x1: 673, x2: 673, y1: 50, y2: 1278 },
    "measure-outside-leg": { x1: 538, x2: 538, y1: 666, y2: 1230 },
    "measure-inside-leg": { x1: 222, x2: 188, y1: 705, y2: 1242 },
    "measure-shoulders": { x1: 748, x2: 1068, y1: 320, y2: 320 },
    "measure-belt-waist": { cx: 908, cy: 608, rx: 98 },
    "measure-arm-length": { d: "M515 300 L612 710" }
  }
}
const svgCache = new Map()

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
    preloadUrls(this.templateValue).forEach((url) => {
      this.fetchSvg(url).catch(() => {})
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

    const svg = await this.fetchSvg(spec.url)
    if (token !== this.loadToken) return
    if (!svg) throw new Error("empty svg")

    const clone = this.buildViewSvg(svg, spec.viewBox)
    this.normalizeGuides(clone)

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

  // Planche PNG = 3 angles. On décale image + mesures pour n'en montrer qu'un
  // (viewBox 0 0 w h), plus fiable que de compter sur le crop viewBox seul.
  buildViewSvg(root, viewBox) {
    const parts = String(viewBox).trim().split(/[\s,]+/).map(Number)
    if (parts.length !== 4 || parts.some((n) => !Number.isFinite(n))) {
      throw new Error(`invalid viewBox: ${viewBox}`)
    }
    const [vx, vy, vw, vh] = parts

    const panel =
      root.querySelector("#measurements")?.closest("svg") ||
      [...root.querySelectorAll("svg")].find((s) => s.querySelector("#measurements")) ||
      root

    const srcImage =
      panel.querySelector("image.base-image") ||
      panel.querySelector("image") ||
      root.querySelector("image")
    const srcMeasures = panel.querySelector("#measurements") || root.querySelector("#measurements")
    if (!srcImage || !srcMeasures) throw new Error("svg missing image/measurements")

    const out = document.createElementNS(NS, "svg")
    out.setAttribute("xmlns", NS)
    out.setAttribute("viewBox", `0 0 ${vw} ${vh}`)
    out.setAttribute("class", "mensuration-figure-svg")
    out.setAttribute("preserveAspectRatio", "xMidYMid meet")
    out.setAttribute("overflow", "hidden")
    out.setAttribute("aria-hidden", "true")
    out.setAttribute("focusable", "false")

    const defs = document.createElementNS(NS, "defs")
    const rootDefs = root.querySelector("defs")
    if (rootDefs) {
      ;[...rootDefs.children].forEach((child) => {
        if (child.localName === "marker") return
        if (child.localName === "style") {
          const style = child.cloneNode(true)
          style.textContent = String(style.textContent || "")
            .replace(/marker-start:\s*url\([^)]+\);?/g, "marker-start: none;")
            .replace(/marker-end:\s*url\([^)]+\);?/g, "marker-end: none;")
          defs.append(style)
          return
        }
        defs.append(child.cloneNode(true))
      })
    }

    const clipId = `mclip-${Math.random().toString(36).slice(2, 9)}`
    const clipPath = document.createElementNS(NS, "clipPath")
    clipPath.setAttribute("id", clipId)
    const clipRect = document.createElementNS(NS, "rect")
    clipRect.setAttribute("x", "0")
    clipRect.setAttribute("y", "0")
    clipRect.setAttribute("width", String(vw))
    clipRect.setAttribute("height", String(vh))
    clipPath.append(clipRect)
    defs.append(clipPath)
    out.append(defs)

    const layer = document.createElementNS(NS, "g")
    layer.setAttribute("clip-path", `url(#${clipId})`)

    const image = srcImage.cloneNode(true)
    image.setAttribute("class", "base-image")
    const href =
      image.getAttribute("href") ||
      image.getAttributeNS(XLINK, "href") ||
      image.getAttribute("xlink:href")
    if (href) {
      image.setAttribute("href", href)
      image.setAttributeNS(XLINK, "href", href)
    }
    // Ancrer le panneau choisi en (0,0) dans le viewBox local.
    const imgW = Number(image.getAttribute("width")) || 1122
    const imgH = Number(image.getAttribute("height")) || 1402
    image.setAttribute("x", String(-vx))
    image.setAttribute("y", String(-vy))
    image.setAttribute("width", String(imgW))
    image.setAttribute("height", String(imgH))
    image.style.pointerEvents = "none"
    layer.append(image)

    const measures = srcMeasures.cloneNode(true)
    measures.setAttribute("transform", `translate(${-vx} ${-vy})`)
    layer.append(measures)
    out.append(layer)

    return out
  }

  makeMeasureGroup(id) {
    const group = document.createElementNS(NS, "g")
    group.setAttribute("id", id)
    group.setAttribute("class", "measurement")
    return group
  }

  ensureMissingGuides(root, tweaks) {
    const measures = root.querySelector("#measurements")
    if (!measures) return

    Object.entries(tweaks).forEach(([id, tweak]) => {
      if (root.querySelector(`#${CSS.escape(id)}`)) return

      const group = this.makeMeasureGroup(id)
      if (tweak.d) {
        const path = document.createElementNS(NS, "path")
        path.setAttribute("class", "guide-arrow")
        path.setAttribute("d", tweak.d)
        group.append(path)
      } else if (tweak.cx != null) {
        const line = document.createElementNS(NS, "line")
        line.setAttribute("class", "guide-arrow")
        line.setAttribute("x1", String(tweak.cx - (tweak.rx || 0)))
        line.setAttribute("y1", String(tweak.cy))
        line.setAttribute("x2", String(tweak.cx + (tweak.rx || 0)))
        line.setAttribute("y2", String(tweak.cy))
        group.append(line)
      } else if (tweak.x1 != null) {
        const line = document.createElementNS(NS, "line")
        line.setAttribute("class", "guide-arrow")
        line.setAttribute("x1", String(tweak.x1))
        line.setAttribute("y1", String(tweak.y1))
        line.setAttribute("x2", String(tweak.x2))
        line.setAttribute("y2", String(tweak.y2))
        group.append(line)
      } else {
        return
      }
      measures.append(group)
    })
  }

  normalizeGuides(root) {
    const tweaks = GUIDE_TWEAKS[this.templateValue] || {}
    this.ensureMissingGuides(root, tweaks)

    root.querySelectorAll("ellipse.guide").forEach((ellipse) => {
      let cx = Number(ellipse.getAttribute("cx"))
      let cy = Number(ellipse.getAttribute("cy"))
      let rx = Number(ellipse.getAttribute("rx"))
      if (![cx, cy, rx].every(Number.isFinite)) return

      const id = ellipse.closest("[id^='measure-']")?.id
      const tweak = id ? tweaks[id] : null
      if (tweak) {
        if (tweak.cx != null) cx = tweak.cx
        if (tweak.cy != null) cy = tweak.cy
        if (tweak.rx != null) rx = tweak.rx
      }

      const line = document.createElementNS(NS, "line")
      line.setAttribute("class", "guide-arrow")
      line.setAttribute("x1", String(cx - rx))
      line.setAttribute("y1", String(cy))
      line.setAttribute("x2", String(cx + rx))
      line.setAttribute("y2", String(cy))
      ellipse.replaceWith(line)
    })

    root.querySelectorAll("#measure-height .helper").forEach((el) => el.remove())

    Object.entries(tweaks).forEach(([id, tweak]) => {
      const group = root.querySelector(`#${CSS.escape(id)}`)
      if (!group) return

      if (tweak.d) {
        group.querySelectorAll("path.guide-arrow, path.hit-area-path").forEach((path) => {
          path.setAttribute("d", tweak.d)
        })
        return
      }

      const line = group.querySelector("line.guide-arrow")
      if (!line) return

      const oldY1 = Number(line.getAttribute("y1"))
      const oldX1 = Number(line.getAttribute("x1"))
      const oldX2 = Number(line.getAttribute("x2"))
      if (tweak.x1 != null) line.setAttribute("x1", String(tweak.x1))
      if (tweak.x2 != null) line.setAttribute("x2", String(tweak.x2))
      if (tweak.y1 != null) line.setAttribute("y1", String(tweak.y1))
      if (tweak.y2 != null) line.setAttribute("y2", String(tweak.y2))

      const helpers = [...group.querySelectorAll("line.helper")]
      if (!helpers.length) return

      const dy = tweak.y1 != null && Number.isFinite(oldY1) ? tweak.y1 - oldY1 : 0
      const newX1 = tweak.x1 != null ? tweak.x1 : oldX1
      const newX2 = tweak.x2 != null ? tweak.x2 : oldX2
      helpers.forEach((helper) => {
        const hx = Number(helper.getAttribute("x1"))
        if (dy) {
          helper.setAttribute("y1", String(Number(helper.getAttribute("y1")) + dy))
          helper.setAttribute("y2", String(Number(helper.getAttribute("y2")) + dy))
        }
        // Tick marks at line ends follow the recalibrated span.
        if (Number.isFinite(hx) && Number.isFinite(oldX1) && Math.abs(hx - oldX1) < 1.5) {
          helper.setAttribute("x1", String(newX1))
          helper.setAttribute("x2", String(newX1))
        } else if (Number.isFinite(hx) && Number.isFinite(oldX2) && Math.abs(hx - oldX2) < 1.5) {
          helper.setAttribute("x1", String(newX2))
          helper.setAttribute("x2", String(newX2))
        }
      })
    })

    root.querySelectorAll(".guide-arrow, .helper").forEach((el) => {
      el.removeAttribute("marker-start")
      el.removeAttribute("marker-end")
      el.style.markerStart = "none"
      el.style.markerEnd = "none"
    })

    this.appendGuideEnds(root)

    root.querySelectorAll(".hit-area, .hit-area-line, .hit-area-path").forEach((el) => {
      el.setAttribute("aria-hidden", "true")
    })
  }

  appendGuideEnds(root) {
    root.querySelectorAll(".measurement").forEach((group) => {
      group.querySelectorAll("circle.guide-end").forEach((el) => el.remove())
      group.querySelectorAll(".guide-arrow").forEach((el) => {
        this.guideEnds(el)?.forEach(([x, y], i) => {
          const dot = document.createElementNS(NS, "circle")
          dot.setAttribute("class", i === 0 ? "guide-end guide-end--start" : "guide-end guide-end--end")
          dot.setAttribute("cx", String(x))
          dot.setAttribute("cy", String(y))
          dot.setAttribute("r", String(GUIDE_END_R))
          group.append(dot)
        })
      })
    })
  }

  guideEnds(el) {
    if (el.localName === "line") {
      const x1 = Number(el.getAttribute("x1"))
      const y1 = Number(el.getAttribute("y1"))
      const x2 = Number(el.getAttribute("x2"))
      const y2 = Number(el.getAttribute("y2"))
      if (![x1, y1, x2, y2].every(Number.isFinite)) return null
      return [[x1, y1], [x2, y2]]
    }
    if (el.localName === "path") return this.pathEnds(el.getAttribute("d"))
    return null
  }

  pathEnds(d) {
    const nums = String(d).match(/-?\d*\.?\d+/g)?.map(Number)
    if (!nums || nums.length < 4) return null
    return [
      [nums[0], nums[1]],
      [nums[nums.length - 2], nums[nums.length - 1]]
    ]
  }

  async fetchSvg(url) {
    const cached = svgCache.get(url)
    if (cached) return cached

    const promise = fetch(url)
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.text()
      })
      .then((text) => {
        let normalized = text
          .replace(/<\/?ns0:/g, (m) => m.replace("ns0:", ""))
          .replace(/\sns0:/g, " ")
          .replace(/\sxmlns:ns0="[^"]*"/g, "")
        if (!/\sxmlns\s*=\s*"http:\/\/www\.w3\.org\/2000\/svg"/.test(normalized)) {
          normalized = normalized.replace(
            /<svg\b/,
            '<svg xmlns="http://www.w3.org/2000/svg"'
          )
        }
        const doc = new DOMParser().parseFromString(normalized, "image/svg+xml")
        const svg = doc.documentElement
        if (!svg || svg.querySelector("parsererror") || svg.localName !== "svg") {
          throw new Error("parse error")
        }
        svgCache.set(url, svg)
        return svg
      })
      .catch((error) => {
        svgCache.delete(url)
        throw error
      })

    svgCache.set(url, promise)
    return promise
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

  dashedDrawPattern(length) {
    const pair = GUIDE_DASH + GUIDE_GAP
    const repeats = Math.ceil(length / pair) + 2
    const dots = Array.from({ length: repeats }, () => `${GUIDE_DASH} ${GUIDE_GAP}`).join(" ")
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
    const arrows = [...node.querySelectorAll(".guide-arrow")]
    const helpers = [...node.querySelectorAll(".helper")]
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
      const length = lengths[i]
      guide.style.strokeDasharray = this.dashedDrawPattern(length)
      guide.style.strokeDashoffset = `${length}`
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
