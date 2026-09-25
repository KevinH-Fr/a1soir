import { Controller } from "@hotwired/stimulus"
import { resolveClip, preloadUrls } from "../mensuration/figure_assets"
import { fetchSvg, renderViewFigure } from "../mensuration/figure_render"

// Fiche admin : 2 silhouettes max (face + profil). Dos → panneau texte.
const VIEW_ORDER = ["face", "profil"]

export default class extends Controller {
  static targets = ["figures", "modal", "lightbox", "lightboxImage"]
  static values = {
    template: { type: String, default: "femme" },
    measures: { type: Array, default: [] }
  }

  connect() {
    this.rendered = false
    this.loadToken = 0
    preloadUrls(this.templateValue).forEach((url) => {
      fetchSvg(url).catch(() => {})
    })

    this.boundShow = () => this.renderFigures()
    this.boundSheetHidden = () => this.closePhoto()
    if (this.hasModalTarget) {
      this.modalTarget.addEventListener("show.bs.modal", this.boundShow)
      this.modalTarget.addEventListener("hidden.bs.modal", this.boundSheetHidden)
    }
  }

  disconnect() {
    if (this.hasModalTarget) {
      this.modalTarget.removeEventListener("show.bs.modal", this.boundShow)
      this.modalTarget.removeEventListener("hidden.bs.modal", this.boundSheetHidden)
    }
    this.closePhoto()
    this.removePrintFrame()
  }

  openPhoto(event) {
    event?.preventDefault()
    event?.stopPropagation()
    const url = event?.params?.url
    if (!url || !this.hasLightboxTarget || !this.hasLightboxImageTarget) return

    this.lightboxImageTarget.src = url
    this.lightboxTarget.hidden = false
    this.lightboxTarget.setAttribute("aria-hidden", "false")
  }

  closePhoto(event) {
    if (event?.target === this.lightboxImageTarget) return
    if (!this.hasLightboxTarget) return

    this.lightboxTarget.hidden = true
    this.lightboxTarget.setAttribute("aria-hidden", "true")
    if (this.hasLightboxImageTarget) this.lightboxImageTarget.removeAttribute("src")
  }

  photoKeydown(event) {
    if (event.key !== "Escape") return
    if (!this.hasLightboxTarget || this.lightboxTarget.hidden) return
    event.preventDefault()
    event.stopImmediatePropagation()
    this.closePhoto()
  }

  async renderFigures() {
    if (!this.hasFiguresTarget || this.rendered) return

    const token = ++this.loadToken
    const panels = this.buildPanels()
    const slots = this.ensureSlots(panels)

    for (let i = 0; i < panels.length; i++) {
      const panel = panels[i]
      const stack = slots[i]
      if (!stack) continue

      try {
        const svg = await renderViewFigure({
          template: this.templateValue,
          view: panel.view,
          measureItems: panel.items
        })
        if (token !== this.loadToken) return

        stack.replaceChildren(svg)
        stack.classList.remove("mensuration-sheet__figure--loading")
        stack.classList.add("mensuration-figure-stack")
      } catch (error) {
        console.warn("[mensuration-sheet] SVG load failed", panel.view, error)
        stack.classList.remove("mensuration-sheet__figure--loading")
        stack.classList.add("mensuration-sheet__figure--error")
      }
    }

    if (token === this.loadToken) {
      this.rendered = true
      this.figuresTarget.removeAttribute("aria-busy")
    }
  }

  ensureSlots(panels) {
    let slots = [...this.figuresTarget.children].filter((el) => (
      el.classList.contains("mensuration-sheet__figure")
    ))

    if (slots.length !== panels.length) {
      this.figuresTarget.replaceChildren()
      slots = panels.map((panel) => {
        const stack = document.createElement("div")
        stack.className = "mensuration-sheet__figure mensuration-sheet__figure--loading"
        stack.dataset.view = panel.view
        stack.setAttribute("aria-hidden", "true")
        this.figuresTarget.append(stack)
        return stack
      })
    } else {
      slots.forEach((stack, i) => {
        stack.dataset.view = panels[i].view
        stack.classList.add("mensuration-sheet__figure--loading")
      })
    }

    return slots
  }

  buildPanels() {
    const byView = this.groupByView()
    return VIEW_ORDER.flatMap((view) => {
      const items = byView[view]
      return items?.length ? [{ view, items }] : []
    })
  }

  groupByView() {
    const groups = { face: [], profil: [] }

    this.measuresValue.forEach((raw) => {
      const clip = raw.clip || raw["clip"]
      const label = raw.label || raw["label"] || ""
      const value = raw.value || raw["value"] || ""
      if (!clip || !value) return

      const spec = resolveClip(clip, this.templateValue)
      if (!spec || !VIEW_ORDER.includes(spec.view)) return

      groups[spec.view].push({
        id: spec.id,
        label,
        value: String(value).includes("cm") ? String(value) : `${value} cm`
      })
    })

    return groups
  }

  printDoc() {
    return this.element.querySelector(".mensuration-sheet-doc")
  }

  absoluteUrl(path) {
    if (!path) return path
    try {
      return new URL(path, window.location.origin).href
    } catch (_error) {
      return path
    }
  }

  /** Clone la fiche telle qu’à l’écran (dimensions figées) pour une impression fiable. */
  buildPrintClone() {
    const doc = this.printDoc()
    if (!doc) return null

    const clone = doc.cloneNode(true)
    clone.querySelectorAll(".no-print").forEach((el) => el.remove())

    const title = clone.querySelector(".mensuration-sheet-doc__title")
    if (title) {
      title.classList.remove("d-none", "d-print-block")
      title.style.display = "block"
      title.style.fontSize = "1.35rem"
      title.style.marginBottom = "0.65rem"
    }

    // Photo print : l’img d-none+lazy n’est souvent jamais chargée → recopier l’image écran.
    const livePhoto = doc.querySelector(".mensuration-sheet-doc__photo-trigger img")
    clone.querySelectorAll(".mensuration-sheet-doc__photo-trigger").forEach((el) => el.remove())
    clone.querySelectorAll(".mensuration-sheet-doc__photo-print").forEach((img) => {
      img.classList.remove("d-none", "d-print-block")
      img.removeAttribute("loading")
      img.style.display = "block"
      img.style.position = "static"
      const src =
        livePhoto?.currentSrc ||
        livePhoto?.getAttribute("src") ||
        img.getAttribute("src")
      if (src) img.setAttribute("src", this.absoluteUrl(src))
    })

    // SVG : tailles explicites (pas absolute+height:auto → collapse / superposition).
    const srcFigs = [...doc.querySelectorAll(".mensuration-sheet__figure")]
    const dstFigs = [...clone.querySelectorAll(".mensuration-sheet__figure")]
    const figuresWrap = clone.querySelector(".mensuration-sheet__figures")
    if (figuresWrap) {
      figuresWrap.style.display = "grid"
      figuresWrap.style.gridTemplateColumns = "1fr 1fr"
      figuresWrap.style.gap = "0.75rem 1rem"
      figuresWrap.style.alignItems = "stretch"
      figuresWrap.style.width = "100%"
    }

    srcFigs.forEach((fig, i) => {
      const dst = dstFigs[i]
      if (!dst) return
      const r = fig.getBoundingClientRect()
      const ratio = r.height > 0 ? r.width / r.height : 760 / 1305
      // Plus large pour les silhouettes ; hauteur dérivée du ratio.
      const targetW = Math.max(Math.round(r.width * 1.35), 320)
      const targetH = Math.round(targetW / ratio)
      dst.style.display = "block"
      dst.style.position = "relative"
      dst.style.width = `${targetW}px`
      dst.style.height = `${targetH}px`
      dst.style.maxWidth = "100%"
      dst.style.minHeight = "0"
      dst.style.aspectRatio = "auto"
      dst.style.overflow = "hidden"
      dst.style.margin = "0"
      dst.style.flex = "none"
    })

    const srcSvgs = [...doc.querySelectorAll(".mensuration-figure-svg")]
    const dstSvgs = [...clone.querySelectorAll(".mensuration-figure-svg")]
    srcSvgs.forEach((_svg, i) => {
      const dst = dstSvgs[i]
      if (!dst) return
      dst.style.position = "absolute"
      dst.style.left = "0"
      dst.style.top = "0"
      dst.style.right = "0"
      dst.style.bottom = "0"
      dst.style.width = "100%"
      dst.style.height = "100%"
      dst.style.maxHeight = "none"
      dst.style.display = "block"
    })

    // Texte : lisible à l’impression (un peu plus large + typo plus grosse).
    const layout = clone.querySelector(".mensuration-sheet-doc__layout")
    if (layout) {
      layout.style.display = "grid"
      layout.style.gridTemplateColumns = "16rem minmax(0, 1fr)"
      layout.style.gap = "0.75rem 1rem"
      layout.style.alignItems = "start"
      layout.style.width = "100%"
    }

    const aside = clone.querySelector(".mensuration-sheet-doc__aside")
    if (aside) {
      aside.style.gap = "0.65rem"
      aside.style.padding = "0.55rem 0.65rem"
      aside.style.minWidth = "15rem"
      aside.style.maxWidth = "16rem"
    }

    clone.querySelectorAll(".mensuration-sheet-doc__block-title").forEach((el) => {
      el.style.fontSize = "0.78rem"
      el.style.marginBottom = "0.28rem"
      el.style.letterSpacing = "0.04em"
    })
    clone.querySelectorAll(".mensuration-sheet-doc__row").forEach((el) => {
      el.style.padding = "0.14rem 0"
    })
    clone.querySelectorAll(".mensuration-sheet-doc__row dt").forEach((el) => {
      el.style.fontSize = "0.88rem"
      el.style.lineHeight = "1.3"
    })
    clone.querySelectorAll(".mensuration-sheet-doc__row dd").forEach((el) => {
      el.style.fontSize = "0.98rem"
      el.style.lineHeight = "1.3"
      el.style.fontWeight = "650"
    })

    // Largeur = texte + 2 SVG côte à côte.
    const figW = dstFigs[0] ? parseInt(dstFigs[0].style.width, 10) : 360
    clone.style.width = `${16 * 16 + 16 + figW * 2 + 20}px`
    clone.style.margin = "0"
    clone.style.background = "#fff"
    clone.style.position = "relative"
    clone.style.overflow = "visible"

    clone.querySelectorAll("img").forEach((img) => {
      const src = img.getAttribute("src")
      if (src) img.setAttribute("src", this.absoluteUrl(src))
    })

    const xlink = "http://www.w3.org/1999/xlink"
    clone.querySelectorAll("image").forEach((image) => {
      const href =
        image.getAttribute("href") ||
        image.getAttributeNS(xlink, "href") ||
        image.getAttribute("xlink:href")
      if (!href) return
      const abs = this.absoluteUrl(href)
      image.setAttribute("href", abs)
      image.setAttributeNS(xlink, "href", abs)
    })

    return clone
  }

  collectStylesHtml() {
    return [...document.querySelectorAll('link[rel="stylesheet"], style')]
      .map((node) => node.outerHTML)
      .join("\n")
  }

  removePrintFrame() {
    this.printFrame?.remove()
    this.printFrame = null
  }

  async print(event) {
    event?.preventDefault()
    this.closePhoto()

    if (!this.rendered) {
      await this.renderFigures()
    }

    const clone = this.buildPrintClone()
    if (!clone) return

    this.removePrintFrame()

    const iframe = document.createElement("iframe")
    iframe.setAttribute("aria-hidden", "true")
    // Largeur desktop réelle : sinon les media queries mobile empilent le texte sous les SVG
    // et il disparaît (coupé par la hauteur de page).
    iframe.style.cssText = "position:fixed;left:-10000px;top:0;width:1200px;height:900px;border:0;opacity:0;pointer-events:none"
    document.body.append(iframe)
    this.printFrame = iframe

    const pageHtml = `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=1200">
  <title>Mensurations</title>
  ${this.collectStylesHtml()}
  <style>
    @page { size: A4 landscape; margin: 0; }
    html, body {
      margin: 0;
      padding: 0;
      background: #fff;
      width: 297mm;
      height: 210mm;
      overflow: hidden;
    }
    #print-sheet {
      transform-origin: top left;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }
    .no-print { display: none !important; }

    /* Forcer layout desktop (2 colonnes) même si le viewport print est étroit. */
    .mensuration-sheet-doc__layout {
      display: grid !important;
      grid-template-columns: 16rem minmax(0, 1fr) !important;
      gap: 0.75rem 1rem !important;
      align-items: start !important;
    }
    .mensuration-sheet-doc__aside,
    .mensuration-sheet-doc__figures-wrap {
      order: 0 !important;
      display: block !important;
      visibility: visible !important;
    }
    .mensuration-sheet-doc__aside {
      max-width: 16rem !important;
      min-width: 15rem !important;
      color: #2a241c !important;
    }
    .mensuration-sheet-doc__block-title {
      font-size: 0.78rem !important;
    }
    .mensuration-sheet-doc__row dt {
      font-size: 0.88rem !important;
      color: #2a241c !important;
      visibility: visible !important;
    }
    .mensuration-sheet-doc__row dd {
      font-size: 0.98rem !important;
      font-weight: 650 !important;
      color: #2a241c !important;
      visibility: visible !important;
    }
    .mensuration-sheet-doc__title {
      font-size: 1.25rem !important;
      color: #2a241c !important;
      visibility: visible !important;
    }
    .mensuration-sheet__figures {
      display: grid !important;
      grid-template-columns: 1fr 1fr !important;
    }
  </style>
</head>
<body>
  <div id="print-sheet">${clone.outerHTML}</div>
</body>
</html>`

    const idoc = iframe.contentDocument
    idoc.open()
    idoc.write(pageHtml)
    idoc.close()

    const waitForImages = () => {
      const images = [...idoc.images]
      if (!images.length) return Promise.resolve()
      return Promise.all(images.map((img) => {
        if (img.complete && img.naturalWidth > 0) return Promise.resolve()
        return new Promise((resolve) => {
          img.addEventListener("load", resolve, { once: true })
          img.addEventListener("error", resolve, { once: true })
        })
      }))
    }

    const finish = () => {
      try {
        const sheet = idoc.getElementById("print-sheet")
        if (sheet) {
          const padMm = 4
          const pageW = ((297 - padMm * 2) / 25.4) * 96
          const pageH = ((210 - padMm * 2) / 25.4) * 96
          const w = Math.max(sheet.scrollWidth, sheet.getBoundingClientRect().width, 1)
          const h = Math.max(sheet.scrollHeight, sheet.getBoundingClientRect().height, 1)
          const scale = Math.min(pageW / w, pageH / h)
          sheet.style.margin = `${padMm}mm`
          sheet.style.transform = `scale(${scale})`
        }
        iframe.contentWindow.focus()
        iframe.contentWindow.print()
      } finally {
        window.setTimeout(() => this.removePrintFrame(), 1000)
      }
    }

    waitForImages().then(() => {
      window.setTimeout(finish, 100)
    })
  }
}
