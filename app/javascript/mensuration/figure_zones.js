const NS = "http://www.w3.org/2000/svg"
const THICK = 8
const FOLD_MS = 220
const UNFOLD_MS = 780
const REDUCED = window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches

export const ZONES = {
  full: { axis: "v", x: 76, y: 4.2, length: 197.9, thick: 5 },
  neck: { axis: "h", x: 95.6, y: 27.5, length: 15.1, thick: 6 },
  shoulders: { axis: "h", x: 78.9, y: 36, length: 48.7 },
  chest: { axis: "h", x: 85.5, y: 55, length: 35.5, thick: 7 },
  torso: { axis: "h", x: 75.3, y: 60, length: 55.7 },
  waist: { axis: "h", x: 84, y: 88, length: 38.5, thick: 7 },
  waist_belt: { axis: "h", x: 83.5, y: 95, length: 39.5, thick: 7 },
  hips: { axis: "h", x: 81, y: 104, length: 44.5, thick: 7 },
  hips_pant: { axis: "h", x: 80.5, y: 111, length: 45.5, thick: 7 },
  arm: { axis: "v", x: 136, y: 36, length: 72, thick: 6 },
  leg: { axis: "v", x: 121, y: 88, length: 110, thick: 6 },
  leg_ext: { axis: "v", x: 121, y: 88, length: 110, thick: 6 },
  leg_int: { axis: "v", x: 109, y: 118, length: 80, thick: 6 },
  feet: { axis: "h", x: 89.9, y: 198, length: 26.5 }
}

function el(name, attrs = {}) {
  const node = document.createElementNS(NS, name)
  Object.entries(attrs).forEach(([key, value]) => node.setAttribute(key, String(value)))
  return node
}

function layoutOf(spec) {
  const thick = spec.thick || THICK
  const vertical = spec.axis === "v"
  const x = vertical ? spec.x - thick / 2 : spec.x
  const y = vertical ? spec.y : spec.y - thick / 2
  const w = vertical ? thick : spec.length
  const h = vertical ? spec.length : thick
  return { ...spec, vertical, thick, x, y, w, h, cx: x + w / 2, cy: y + h / 2 }
}

function collapsed(layout) {
  return layout.vertical
    ? { x: layout.x, y: layout.cy, w: layout.w, h: 0 }
    : { x: layout.cx, y: layout.y, w: 0, h: layout.h }
}

function lerp(a, b, t) {
  return a + (b - a) * t
}

function easeInCubic(t) {
  return t * t * t
}

function easeOutCubic(t) {
  return 1 - (1 - t) ** 3
}

function lerpBox(from, to, t) {
  return {
    x: lerp(from.x, to.x, t),
    y: lerp(from.y, to.y, t),
    w: lerp(from.w, to.w, t),
    h: lerp(from.h, to.h, t)
  }
}

function setBox(node, box) {
  if (!node) return
  node.setAttribute("x", box.x)
  node.setAttribute("y", box.y)
  node.setAttribute("width", Math.max(0, box.w))
  node.setAttribute("height", Math.max(0, box.h))
}

function setLine(node, x1, y1, x2, y2) {
  node.setAttribute("x1", x1)
  node.setAttribute("y1", y1)
  node.setAttribute("x2", x2)
  node.setAttribute("y2", y2)
}

function spineOf(layout) {
  return layout.vertical
    ? { x1: layout.cx, y1: layout.y, x2: layout.cx, y2: layout.y + layout.h }
    : { x1: layout.x, y1: layout.cy, x2: layout.x + layout.w, y2: layout.cy }
}

function capOf(layout, which) {
  const span = layout.thick + 5
  if (layout.vertical) {
    const y = which === 0 ? layout.y : layout.y + layout.h
    return { x1: layout.cx - span / 2, y1: y, x2: layout.cx + span / 2, y2: y }
  }
  const x = which === 0 ? layout.x : layout.x + layout.w
  return { x1: x, y1: layout.cy - span / 2, x2: x, y2: layout.cy + span / 2 }
}

function knobOf(layout, which) {
  if (layout.vertical) {
    return { cx: layout.cx, cy: which === 0 ? layout.y : layout.y + layout.h }
  }
  return { cx: which === 0 ? layout.x : layout.x + layout.w, cy: layout.cy }
}

function placeLabel(nodes, layout, label) {
  const str = label || "cm"
  const compact = str.length > 16
  const fs = compact ? 5.4 : 6.3
  const padX = compact ? 3.1 : 3.6
  const w = Math.max(18, str.length * (compact ? 3.15 : 3.65)) + padX * 2
  const h = 10.2
  let x
  let y
  if (layout.vertical) {
    const left = layout.cx < 103
    x = left ? layout.x - w - 5 : layout.x + layout.w + 5
    if (x < 1) x = layout.x + layout.w + 5
    if (x + w > 205) x = layout.x - w - 5
    y = layout.cy - h / 2
  } else {
    x = layout.cx - w / 2
    y = layout.y - h - 4.5
    if (y < 1) y = layout.y + layout.h + 4.5
    if (x < 1) x = 1
    if (x + w > 205) x = 205 - w
  }
  setBox(nodes.badge, { x, y, w, h })
  nodes.badge.setAttribute("rx", h / 2)
  nodes.label.setAttribute("x", x + w / 2)
  nodes.label.setAttribute("y", y + h / 2 + 0.2)
  nodes.label.setAttribute("font-size", fs)
  nodes.label.removeAttribute("transform")
  nodes.label.textContent = str
}

function ensureStructure(ruler) {
  if (ruler.dataset.built === "v2") return
  ruler.replaceChildren()
  const uid = `rr-${Math.random().toString(36).slice(2, 8)}`
  const defs = el("defs")
  const clipPath = el("clipPath", { id: uid })
  clipPath.append(el("rect", { class: "measure-ruler__clip" }))
  defs.append(clipPath)

  const inner = el("g", { class: "measure-ruler__inner", "clip-path": `url(#${uid})` })
  inner.append(el("rect", { class: "measure-ruler__band" }))
  inner.append(el("line", { class: "measure-ruler__spine" }))

  const marks = el("g", { class: "measure-ruler__marks" })
  marks.append(el("line", { class: "measure-ruler__cap" }))
  marks.append(el("line", { class: "measure-ruler__cap" }))
  marks.append(el("circle", { class: "measure-ruler__knob", r: 2.2 }))
  marks.append(el("circle", { class: "measure-ruler__knob", r: 2.2 }))

  ruler.append(
    defs,
    inner,
    marks,
    el("rect", { class: "measure-ruler__badge" }),
    el("text", {
      class: "measure-ruler__label",
      "text-anchor": "middle",
      "dominant-baseline": "middle"
    })
  )
  ruler.dataset.built = "v2"
  ruler._anim = 0
}

function parts(ruler) {
  return {
    clip: ruler.querySelector(".measure-ruler__clip"),
    band: ruler.querySelector(".measure-ruler__band"),
    spine: ruler.querySelector(".measure-ruler__spine"),
    caps: ruler.querySelectorAll(".measure-ruler__cap"),
    knobs: ruler.querySelectorAll(".measure-ruler__knob"),
    badge: ruler.querySelector(".measure-ruler__badge"),
    label: ruler.querySelector(".measure-ruler__label")
  }
}

function paint(ruler, layout, label) {
  const nodes = parts(ruler)
  setBox(nodes.band, layout)
  nodes.band.setAttribute("rx", Math.min(layout.w, layout.h) / 2)
  const spine = spineOf(layout)
  setLine(nodes.spine, spine.x1, spine.y1, spine.x2, spine.y2)
  ;[0, 1].forEach((i) => {
    const cap = capOf(layout, i)
    setLine(nodes.caps[i], cap.x1, cap.y1, cap.x2, cap.y2)
    const knob = knobOf(layout, i)
    nodes.knobs[i].setAttribute("cx", knob.cx)
    nodes.knobs[i].setAttribute("cy", knob.cy)
  })
  placeLabel(nodes, layout, label)
  ruler.classList.toggle("measure-ruler--h", !layout.vertical)
  ruler.classList.toggle("measure-ruler--v", layout.vertical)
}

function setLive(ruler, on) {
  ruler.classList.toggle("is-live", Boolean(on) && !REDUCED)
}

function setMarked(ruler, on) {
  ruler.classList.toggle("is-marked", Boolean(on))
}

function stopAnim(ruler) {
  ruler._anim = (ruler._anim || 0) + 1
  return ruler._anim
}

function runBox(ruler, token, from, to, duration, easing, onDone) {
  const clip = parts(ruler).clip
  const start = performance.now()
  const step = (now) => {
    if (ruler._anim !== token) return
    const t = Math.min(1, (now - start) / duration)
    setBox(clip, lerpBox(from, to, easing(t)))
    if (t < 1) requestAnimationFrame(step)
    else onDone?.()
  }
  requestAnimationFrame(step)
}

function unfoldOn(ruler, token, layout, label) {
  const { clip } = parts(ruler)
  paint(ruler, layout, label)
  setBox(clip, collapsed(layout))
  ruler._layout = layout
  runBox(ruler, token, collapsed(layout), layout, UNFOLD_MS, easeOutCubic, () => {
    if (ruler._anim !== token) return
    setBox(clip, layout)
    setMarked(ruler, true)
    setLive(ruler, true)
  })
}

export function hideRuler(ruler) {
  if (!ruler) return
  stopAnim(ruler)
  setLive(ruler, false)
  setMarked(ruler, false)
  ruler.classList.remove("is-on")
  const clip = ruler.querySelector(".measure-ruler__clip")
  const layout = ruler._layout
  if (clip && layout) setBox(clip, collapsed(layout))
  ruler._layout = null
}

export function drawRuler(ruler, spec, label) {
  if (!ruler || !spec) return
  ensureStructure(ruler)
  const to = layoutOf(spec)
  const from = ruler._layout
  const token = stopAnim(ruler)

  ruler.classList.add("is-on")
  setLive(ruler, false)
  setMarked(ruler, false)

  if (REDUCED) {
    paint(ruler, to, label)
    setBox(parts(ruler).clip, to)
    setMarked(ruler, true)
    ruler._layout = to
    return
  }

  if (!from) {
    unfoldOn(ruler, token, to, label)
    return
  }

  runBox(ruler, token, from, collapsed(from), FOLD_MS, easeInCubic, () => {
    if (ruler._anim !== token) return
    unfoldOn(ruler, token, to, label)
  })
}

export function setRulerLabel(ruler, label) {
  if (!ruler) return
  const nodes = parts(ruler)
  if (!nodes.label) return
  if (ruler._layout) placeLabel(nodes, ruler._layout, label)
  else nodes.label.textContent = label || "cm"
}
