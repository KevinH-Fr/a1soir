// clip YAML → vue SVG + id du groupe #measure-*
// viewBox = crop dans la planche 1122×1402 (3 angles côte à côte).
const VIEW_BOX = {
  femme: {
    face: "37 40 381 1305",
    profil: "410 40 340 1305",
    dos: "726 40 374 1305"
  },
  homme: {
    face: "30 40 380 1305",
    profil: "414 40 301 1305",
    dos: "716 40 380 1305"
  }
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
    url: `/images/mensurations_${gender}_${base.view}.svg`,
    viewBox: VIEW_BOX[gender][base.view]
  }
}

export function preloadUrls(template) {
  const t = template === "homme" ? "homme" : "femme"
  return ["face", "profil", "dos"].map((view) => `/images/mensurations_${t}_${view}.svg`)
}
