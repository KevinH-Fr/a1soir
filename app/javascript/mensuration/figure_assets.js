// clip YAML → vue SVG + id du groupe #measure-*
// viewBox = crop dans la planche 1122×1402 (3 angles côte à côte).
export const VIEW_BOX = {
  femme: {
    face: "37 40 381 1305",
    profil: "410 40 340 1305",
    dos: "726 40 374 1305"
  },
  homme: {
    // new2 = vues 440×1385 ; crop serré (laisse de la place à droite pour measure-height)
    face: "56 109 329 1132",
    profil: "115 40 230 1305",
    dos: "716 40 380 1305"
  }
}

// Surcharge de nom de fichier (cache-bust / version Inkscape).
const SVG_FILE = {
  "homme/face": "mensurations_homme_face.svg",
  "homme/profil": "mensurations_homme_profil.svg"
}

export function svgUrl(template, view) {
  const gender = template === "homme" ? "homme" : "femme"
  const override = SVG_FILE[`${gender}/${view}`]
  const file = override || `mensurations_${gender}_${view}.svg`
  return `/images/${file}`
}

const CLIP_MAP = {
  full: { view: "profil", id: "measure-height" },
  neck: { view: "face", id: "measure-neck" },
  chest: { view: "face", id: "measure-bust" },
  torso: { view: "face", id: "measure-underbust" },
  waist: { view: "face", id: "measure-waist" },
  hips: { view: "face", id: "measure-hips" },
  hips_pant: { view: "face", id: "measure-hips" },
  thigh: { view: "face", id: "measure-thigh" },
  arm: { view: "profil", id: "measure-arm-length" },
  leg_ext: { view: "profil", id: "measure-outside-leg" },
  leg_int: { view: "face", id: "measure-inside-leg" },
  shoulders: { view: "dos", id: "measure-shoulders" },
  waist_belt: { view: "dos", id: "measure-belt-waist" }
}

export function resolveClip(clip, template = "femme") {
  const base = CLIP_MAP[clip]
  if (!base) return null

  const gender = template === "homme" ? "homme" : "femme"
  const id =
    clip === "chest" && gender === "homme" ? "measure-chest" : base.id

  return {
    view: base.view,
    id,
    url: svgUrl(gender, base.view),
    viewBox: VIEW_BOX[gender][base.view]
  }
}

export function preloadUrls(template, views = ["face", "profil"]) {
  const t = template === "homme" ? "homme" : "femme"
  return views.map((view) => svgUrl(t, view))
}
