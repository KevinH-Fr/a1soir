// Rendu SVG silhouette (crop vue + guides) — partagé guide public / fiche admin.
import { VIEW_BOX, svgUrl } from "./figure_assets"

export const NS = "http://www.w3.org/2000/svg"
export const XLINK = "http://www.w3.org/1999/xlink"
export const GUIDE_END_R = 4.4

// Recalage visuel sur la planche 1122×1402 (ellipse → cx/cy/rx ; ligne → x/y).
export const GUIDE_TWEAKS = {
  femme: {
    "measure-neck": { cx: 232, cy: 258, rx: 42, ry: 0 },
    "measure-bust": { cx: 233, cy: 392, rx: 79, ry: 8 },
    "measure-underbust": { cx: 233, cy: 438, rx: 74, ry: 7 },
    "measure-waist": { cx: 233, cy: 518, rx: 64, ry: 6 },
    "measure-hips": { cx: 232, cy: 668, rx: 122 },
    "measure-thigh": { cx: 174, cy: 778, rx: 46 },
    "measure-height": { x1: 678, x2: 678, y1: 50, y2: 1300 },
    "measure-outside-leg": { x1: 546, x2: 546, y1: 590, y2: 1268 },
    "measure-inside-leg": { x1: 225, x2: 205, y1: 705, y2: 1265 },
    "measure-shoulders": { x1: 783, x2: 1045, y1: 302, y2: 302 },
    "measure-belt-waist": { cx: 918, cy: 576, rx: 88, ry: 6 },
    "measure-arm-length": { d: "M540 302 L618 704" }
  },
  homme: {
    "measure-neck": { cx: 226, cy: 248, rx: 34, ry: 0 },
    "measure-chest": { cx: 220, cy: 370, rx: 95, ry: 7 },
    "measure-waist": { cx: 224, cy: 508, rx: 90, ry: 6 },
    "measure-hips": { cx: 220, cy: 678, rx: 114 },
    "measure-thigh": { cx: 164, cy: 768, rx: 48 },
    "measure-height": { x1: 673, x2: 673, y1: 50, y2: 1278 },
    "measure-outside-leg": { x1: 538, x2: 538, y1: 575, y2: 1230 },
    "measure-inside-leg": { x1: 222, x2: 188, y1: 765, y2: 1242 },
    "measure-shoulders": { x1: 748, x2: 1068, y1: 320, y2: 320 },
    "measure-belt-waist": { cx: 908, cy: 588, rx: 98 },
    "measure-arm-length": { d: "M515 320 L612 710" }
  }
}

const svgCache = new Map()

export function clearSvgCache() {
  svgCache.clear()
}

export function viewSpec(view, template = "femme") {
  const gender = template === "homme" ? "homme" : "femme"
  return {
    view,
    url: svgUrl(gender, view),
    viewBox: VIEW_BOX[gender][view]
  }
}

export async function fetchSvg(url) {
  const cached = svgCache.get(url)
  if (cached) return cached

  // no-cache : revalide côté serveur (évite de garder une vieille silhouette après edit Inkscape).
  const promise = fetch(url, { cache: "no-cache" })
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

// Planche PNG = 3 angles. On décale image + mesures pour n'en montrer qu'un
// (viewBox 0 0 w h), plus fiable que de compter sur le crop viewBox seul.
export function buildViewSvg(root, viewBox) {
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
  out.dataset.vx = String(vx)
  out.dataset.vy = String(vy)
  out.dataset.vw = String(vw)
  out.dataset.vh = String(vh)

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
  const imgW = Number(image.getAttribute("width")) || 1122
  const imgH = Number(image.getAttribute("height")) || 1402
  image.setAttribute("x", String(-vx))
  image.setAttribute("y", String(-vy))
  image.setAttribute("width", String(imgW))
  image.setAttribute("height", String(imgH))
  image.style.pointerEvents = "none"
  layer.append(image)

  const measures = srcMeasures.cloneNode(true)
  // Garder un transform d'alignement éventuel (SVG new2) puis appliquer le crop viewBox.
  const alignTx = (srcMeasures.getAttribute("transform") || "").trim()
  const cropTx = `translate(${-vx} ${-vy})`
  measures.setAttribute("transform", alignTx ? `${cropTx} ${alignTx}` : cropTx)
  if (alignTx) out.dataset.alignTransform = alignTx
  layer.append(measures)
  out.append(layer)

  return out
}

function wrapPaths(cx, cy, rx, ry, invert = false) {
  const depth = Math.min(Math.max(ry, 3), rx * 0.07)
  const bottomD = `M ${cx - rx} ${cy} A ${rx} ${depth} 0 0 1 ${cx + rx} ${cy}`
  const topD = `M ${cx + rx} ${cy} A ${rx} ${depth} 0 0 0 ${cx - rx} ${cy}`
  const frontD = invert ? topD : bottomD
  const backD = invert ? bottomD : topD

  const halo = document.createElementNS(NS, "path")
  halo.setAttribute("class", "guide-arrow--wrap guide-arrow--back-halo")
  halo.setAttribute("fill", "none")
  halo.setAttribute("d", backD)

  const back = document.createElementNS(NS, "path")
  back.setAttribute("class", "guide-arrow guide-arrow--wrap guide-arrow--back")
  back.setAttribute("fill", "none")
  back.setAttribute("d", backD)

  const front = document.createElementNS(NS, "path")
  front.setAttribute("class", "guide-arrow guide-arrow--wrap guide-arrow--front")
  front.setAttribute("fill", "none")
  front.setAttribute("d", frontD)

  return [halo, back, front]
}

function makeMeasureGroup(id) {
  const group = document.createElementNS(NS, "g")
  group.setAttribute("id", id)
  group.setAttribute("class", "measurement")
  return group
}

function pathEnds(d) {
  const nums = String(d).match(/-?\d*\.?\d+/g)?.map(Number)
  if (!nums || nums.length < 4) return null
  return [
    [nums[0], nums[1]],
    [nums[nums.length - 2], nums[nums.length - 1]]
  ]
}

function guideEnds(el) {
  if (el.localName === "line") {
    const x1 = Number(el.getAttribute("x1"))
    const y1 = Number(el.getAttribute("y1"))
    const x2 = Number(el.getAttribute("x2"))
    const y2 = Number(el.getAttribute("y2"))
    if (![x1, y1, x2, y2].every(Number.isFinite)) return null
    return [[x1, y1], [x2, y2]]
  }
  if (el.localName === "path") return pathEnds(el.getAttribute("d"))
  return null
}

function appendGuideEnds(root) {
  root.querySelectorAll(".measurement").forEach((group) => {
    group.querySelectorAll("circle.guide-end").forEach((el) => el.remove())
    group.querySelectorAll(".guide-arrow").forEach((el) => {
      if (el.classList.contains("guide-arrow--wrap")) return
      guideEnds(el)?.forEach(([x, y], i) => {
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

function ensureMissingGuides(root, tweaks) {
  const measures = root.querySelector("#measurements")
  if (!measures) return

  Object.entries(tweaks).forEach(([id, tweak]) => {
    if (root.querySelector(`#${CSS.escape(id)}`)) return

    const group = makeMeasureGroup(id)
    if (tweak.d) {
      const path = document.createElementNS(NS, "path")
      path.setAttribute("class", "guide-arrow")
      path.setAttribute("d", tweak.d)
      group.append(path)
    } else if (tweak.cx != null && tweak.ry) {
      group.append(...wrapPaths(tweak.cx, tweak.cy, tweak.rx || 0, tweak.ry, Boolean(tweak.invert)))
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

export function normalizeGuides(root, template = "femme") {
  const tweaks = GUIDE_TWEAKS[template === "homme" ? "homme" : "femme"] || {}
  ensureMissingGuides(root, tweaks)

  root.querySelectorAll("ellipse.guide").forEach((ellipse) => {
    let cx = Number(ellipse.getAttribute("cx"))
    let cy = Number(ellipse.getAttribute("cy"))
    let rx = Number(ellipse.getAttribute("rx"))
    let ry = Number(ellipse.getAttribute("ry"))
    if (![cx, cy, rx].every(Number.isFinite)) return

    const id = ellipse.closest("[id^='measure-']")?.id
    const tweak = id ? tweaks[id] : null
    if (tweak) {
      if (tweak.cx != null) cx = tweak.cx
      if (tweak.cy != null) cy = tweak.cy
      if (tweak.rx != null) rx = tweak.rx
      if (tweak.ry != null) ry = tweak.ry
    }

    if (Number.isFinite(ry) && ry > 0) {
      ellipse.replaceWith(...wrapPaths(cx, cy, rx, ry, Boolean(tweak?.invert)))
      return
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

  appendGuideEnds(root)

  root.querySelectorAll(".hit-area, .hit-area-line, .hit-area-path").forEach((el) => {
    el.setAttribute("aria-hidden", "true")
  })
}

/** Active plusieurs mesures en mode statique (fiche admin / impression). */
export function activateMeasuresStatic(root, ids) {
  root.querySelectorAll(".measurement.is-active").forEach((el) => {
    el.classList.remove("is-active", "is-animating", "is-drawing", "is-settled")
  })
  ids.forEach((id) => {
    const node = root.querySelector(`#${CSS.escape(id)}`)
    if (!node) return
    node.classList.add("is-active", "is-animating", "is-settled")
  })
}

/**
 * Point milieu du guide (pastille) + bords pour le filet vers le libellé.
 * Coords planche (avant crop), comme les #measure-*.
 */
export function measureGuideAnchor(group) {
  const wrap = group.querySelector(".guide-arrow--front") || group.querySelector(".guide-arrow--wrap")
  const line = group.querySelector("line.guide-arrow")
  const path = group.querySelector("path.guide-arrow:not(.guide-arrow--wrap)")

  if (line) {
    const x1 = Number(line.getAttribute("x1"))
    const y1 = Number(line.getAttribute("y1"))
    const x2 = Number(line.getAttribute("x2"))
    const y2 = Number(line.getAttribute("y2"))
    if (![x1, y1, x2, y2].every(Number.isFinite)) return null
    const midX = (x1 + x2) / 2
    const midY = (y1 + y2) / 2
    return {
      midX,
      midY,
      cy: midY,
      edgeLeft: Math.min(x1, x2),
      edgeRight: Math.max(x1, x2),
      vertical: Math.abs(x2 - x1) < Math.abs(y2 - y1)
    }
  }

  if (path) {
    const ends = pathEnds(path.getAttribute("d"))
    if (!ends) return null
    const [[x1, y1], [x2, y2]] = ends
    const midX = (x1 + x2) / 2
    const midY = (y1 + y2) / 2
    return {
      midX,
      midY,
      cy: midY,
      edgeLeft: Math.min(x1, x2),
      edgeRight: Math.max(x1, x2),
      vertical: Math.abs(x2 - x1) < Math.abs(y2 - y1)
    }
  }

  if (wrap) {
    const nums = String(wrap.getAttribute("d")).match(/-?\d*\.?\d+/g)?.map(Number)
    if (nums && nums.length >= 4) {
      const x0 = nums[0]
      const y0 = nums[1]
      const x1 = nums.length >= 6 ? nums[nums.length - 2] : nums[2]
      const midX = (x0 + x1) / 2
      const midY = y0
      return {
        midX,
        midY,
        cy: midY,
        edgeLeft: Math.min(x0, x1),
        edgeRight: Math.max(x0, x1),
        vertical: false
      }
    }
  }

  try {
    const box = group.getBBox()
    const midX = box.x + box.width / 2
    const midY = box.y + box.height / 2
    return {
      midX,
      midY,
      cy: midY,
      edgeLeft: box.x,
      edgeRight: box.x + box.width,
      vertical: box.height > box.width
    }
  } catch (_) {
    return null
  }
}

/** @deprecated préférer measureGuideAnchor */
export function measureLabelAnchor(group) {
  const a = measureGuideAnchor(group)
  if (!a) return null
  return { x: a.edgeRight, y: a.midY, side: "right", cy: a.cy }
}

function chipDisplayValue(value) {
  const raw = String(value).trim()
  const bare = raw.replace(/\s*cm\s*$/i, "").trim()
  return bare.length ? bare : raw
}

function appendValueChip(parent, midX, midY, value) {
  const display = chipDisplayValue(value)
  const g = document.createElementNS(NS, "g")
  g.setAttribute("class", "mensuration-figure-chip")
  g.setAttribute("transform", `translate(${midX} ${midY})`)

  const w = Math.max(48, display.length * 14 + 22)
  const h = 32
  const bg = document.createElementNS(NS, "rect")
  bg.setAttribute("class", "mensuration-figure-chip__bg")
  bg.setAttribute("x", String(-w / 2))
  bg.setAttribute("y", String(-h / 2))
  bg.setAttribute("width", String(w))
  bg.setAttribute("height", String(h))
  bg.setAttribute("rx", String(h / 2))

  const text = document.createElementNS(NS, "text")
  text.setAttribute("class", "mensuration-figure-chip__value")
  text.setAttribute("text-anchor", "middle")
  text.setAttribute("dominant-baseline", "central")
  text.setAttribute("y", "0.5")
  text.textContent = display

  g.append(bg, text)
  parent.append(g)
  return w / 2
}

/**
 * Pastille valeur sur le guide + libellé court à côté relié par un filet.
 */
export function placeMeasureLabels(svg, items) {
  const vx = Number(svg.dataset.vx) || 0
  const vy = Number(svg.dataset.vy) || 0
  const vw = Number(svg.dataset.vw) || 0
  const vh = Number(svg.dataset.vh) || 0
  const sidePad = 190

  svg.setAttribute("viewBox", `${-sidePad} 0 ${vw + sidePad * 2} ${vh}`)
  svg.setAttribute("overflow", "visible")

  const labelsLayer = document.createElementNS(NS, "g")
  labelsLayer.setAttribute("class", "mensuration-figure-labels")
  const alignTx = (svg.dataset.alignTransform || "").trim()
  const cropTx = `translate(${-vx} ${-vy})`
  labelsLayer.setAttribute("transform", alignTx ? `${cropTx} ${alignTx}` : cropTx)
  svg.append(labelsLayer)

  const prepared = items.map((item) => {
    const group = svg.querySelector(`#${CSS.escape(item.id)}`)
    if (!group) return null
    const anchor = measureGuideAnchor(group)
    if (!anchor) return null
    return { item, group, anchor, cy: anchor.cy }
  }).filter(Boolean)

  prepared.sort((a, b) => a.cy - b.cy)

  // Côté préféré par mesure (profil surtout) — sinon alternance haut→bas.
  const PREFERRED_SIDE = {
    "measure-arm-length": "left",
    "measure-height": "right",
    "measure-outside-leg": "left"
  }

  const placed = []
  const MIN_DY = 34

  prepared.forEach((entry, index) => {
    const { midX, midY, edgeLeft, edgeRight } = entry.anchor
    const preferred = PREFERRED_SIDE[entry.item.id]
    let side = preferred || (index % 2 === 0 ? "right" : "left")
    let labelY = midY
    const lockedSide = Boolean(preferred)

    let attempts = 0
    while (attempts < 6) {
      const clash = placed.find((p) => p.side === side && Math.abs(p.cy - labelY) < MIN_DY)
      if (!clash) break
      if (lockedSide) {
        // Garder le côté demandé : décaler seulement en hauteur.
        labelY = clash.cy + MIN_DY
      } else if (attempts % 2 === 0) {
        side = side === "right" ? "left" : "right"
      } else {
        labelY = clash.cy + MIN_DY
      }
      attempts++
    }

    const halfChip = appendValueChip(labelsLayer, midX, midY, entry.item.value)

    // Filet assez long pour sortir clairement hors de la silhouette.
    const stub = 28
    const labelGap = 36
    const chipEdgeX = side === "right" ? midX + halfChip : midX - halfChip
    const startX = side === "right"
      ? Math.max(chipEdgeX, edgeRight) + stub
      : Math.min(chipEdgeX, edgeLeft) - stub
    const labelX = side === "right" ? startX + labelGap : startX - labelGap

    const connector = document.createElementNS(NS, "path")
    connector.setAttribute("class", "mensuration-figure-leader")
    connector.setAttribute("fill", "none")
    connector.setAttribute(
      "d",
      `M ${chipEdgeX} ${midY} L ${startX} ${midY} L ${labelX} ${labelY}`
    )
    labelsLayer.append(connector)

    const text = document.createElementNS(NS, "text")
    text.setAttribute("class", "mensuration-figure-label")
    text.setAttribute("x", String(labelX))
    text.setAttribute("y", String(labelY))
    text.setAttribute("text-anchor", side === "right" ? "start" : "end")
    text.setAttribute("dominant-baseline", "middle")
    text.textContent = entry.item.label

    labelsLayer.append(text)
    placed.push({ cy: labelY, side })
  })
}

export async function renderViewFigure({ template, view, measureItems }) {
  const spec = viewSpec(view, template)
  const root = await fetchSvg(spec.url)
  const svg = buildViewSvg(root, spec.viewBox)
  normalizeGuides(svg, template)

  const ids = measureItems.map((m) => m.id)

  // getBBox nécessite un SVG rattaché (libellés).
  const host = document.createElement("div")
  host.setAttribute("aria-hidden", "true")
  host.style.cssText = "position:absolute;left:-99999px;top:0;width:28rem;height:0;overflow:hidden;pointer-events:none"
  document.body.append(host)
  host.append(svg)

  try {
    activateMeasuresStatic(svg, ids)
    placeMeasureLabels(svg, measureItems)
    // Attributs width/height explicites : Chrome print gère mal le seul viewBox.
    const parts = String(svg.getAttribute("viewBox") || "").trim().split(/[\s,]+/).map(Number)
    if (parts.length === 4 && parts.every(Number.isFinite)) {
      svg.setAttribute("width", String(parts[2]))
      svg.setAttribute("height", String(parts[3]))
    }
  } finally {
    svg.remove()
    host.remove()
  }

  return svg
}
