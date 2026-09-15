const centerTextPlugin = {
  id: "analysesCenterText",
  afterDatasetsDraw(chart) {
    const lines = chart.options.plugins?.analysesCenterText?.lines
    if (!lines?.length) return

    const { ctx } = chart
    const meta = chart.getDatasetMeta(0)
    const el = meta?.data?.[0]
    if (!el) return

    const x = el.x
    const y = el.y
    ctx.save()
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"

    if (lines.length === 1) {
      ctx.font = "600 13px system-ui, sans-serif"
      ctx.fillStyle = "#334155"
      ctx.fillText(lines[0], x, y)
    } else if (lines.length === 2 && /TTC|HT/.test(String(lines[0]))) {
      // Montant TTC (fort) puis montant HT (discret)
      ctx.font = "700 13px system-ui, sans-serif"
      ctx.fillStyle = "#1e293b"
      ctx.fillText(lines[0], x, y - 8)
      ctx.font = "500 11px system-ui, sans-serif"
      ctx.fillStyle = "#64748b"
      ctx.fillText(lines[1], x, y + 10)
    } else if (lines.length === 2) {
      // Valeur forte + libellé discret (ex. total + "articles")
      ctx.font = "700 16px system-ui, sans-serif"
      ctx.fillStyle = "#1e293b"
      ctx.fillText(lines[0], x, y - 8)
      ctx.font = "500 10px system-ui, sans-serif"
      ctx.fillStyle = "#64748b"
      ctx.fillText(lines[1], x, y + 10)
    } else if (lines.length === 3 && /articles/i.test(String(lines[1]))) {
      // Catalogue dual : qté + "articles" + CA €
      ctx.font = "700 15px system-ui, sans-serif"
      ctx.fillStyle = "#1e293b"
      ctx.fillText(lines[0], x, y - 12)
      ctx.font = "500 10px system-ui, sans-serif"
      ctx.fillStyle = "#64748b"
      ctx.fillText(lines[1], x, y + 2)
      ctx.font = "600 11px system-ui, sans-serif"
      ctx.fillStyle = "#475569"
      ctx.fillText(lines[2], x, y + 16)
    } else {
      ctx.font = "700 13px system-ui, sans-serif"
      ctx.fillStyle = "#1e293b"
      ctx.fillText(lines[0], x, y - 10)
      ctx.font = "500 11px system-ui, sans-serif"
      ctx.fillStyle = "#64748b"
      lines.slice(1).forEach((line, i) => {
        ctx.fillText(line, x, y + 6 + (i * 12))
      })
    }
    ctx.restore()
  }
}

function formatEuro(value) {
  if (value == null || Number.isNaN(Number(value))) return ""
  return `${Math.round(Number(value)).toLocaleString("fr-FR")} €`
}

function formatInteger(value) {
  if (value == null || Number.isNaN(Number(value))) return ""
  return Math.round(Number(value)).toLocaleString("fr-FR")
}

function roundDatasetValues(config) {
  config.data?.datasets?.forEach((dataset) => {
    if (!Array.isArray(dataset.data)) return
    dataset.data = dataset.data.map((value) => {
      if (value == null || typeof value !== "number") return value
      return Math.round(value)
    })
  })
}

function applyIntegerAxisTicks(config) {
  const scales = config.options?.scales
  if (!scales) return

  Object.values(scales).forEach((scale) => {
    if (!scale || typeof scale !== "object") return
    scale.ticks = {
      ...(scale.ticks || {}),
      precision: 0
    }
  })
}

function axisLooksLikeMoney(config) {
  const scales = config.options?.scales || {}
  return Object.values(scales).some((scale) => {
    const title = scale?.title?.text
    return typeof title === "string" && title.includes("€")
  })
}

function applyTooltipStyle(config) {
  config.options.plugins.tooltip = {
    ...(config.options.plugins.tooltip || {}),
    backgroundColor: "rgba(255, 255, 255, 0.97)",
    titleColor: "#1e293b",
    bodyColor: "#475569",
    borderColor: "rgba(15, 23, 42, 0.08)",
    borderWidth: 1,
    cornerRadius: 8,
    padding: 10,
    displayColors: true,
    boxPadding: 4,
    titleFont: { size: 11, weight: "600" },
    bodyFont: { size: 12, weight: "500" },
    caretSize: 5
  }
}

function prefersReducedMotion() {
  return typeof window !== "undefined" &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches
}

function yPixelFromZero(ctx) {
  if (ctx.type !== "data") return
  // Uniquement au premier rendu — sinon un resize / update rejoue l'anim depuis 0.
  if (ctx.mode !== "default" || ctx.chart?.$analysesSettled) return
  const scaleId = ctx.dataset?.yAxisID || "y"
  const scale = ctx.chart?.scales?.[scaleId]
  if (!scale || typeof scale.getPixelForValue !== "function") return
  return scale.getPixelForValue(0)
}

function markChartSettled(animation) {
  const chart = animation?.chart
  if (!chart || chart.$analysesSettled) return
  chart.$analysesSettled = true
}

/** Animations partagées pour tous les charts Analyses (montage + refresh). */
function applyAnimations(config) {
  if (prefersReducedMotion() || config.options.animation === false) {
    config.options.animation = false
    config.options.transitions = {
      active: { animation: { duration: 0 } },
      resize: { animation: { duration: 0 } }
    }
    return
  }

  const doughnut = config.type === "doughnut"
  const lineLike = !doughnut && (
    config.type === "line" ||
    (config.data?.datasets || []).some((ds) => ds.type === "line")
  )
  const existing = typeof config.options.animation === "object" ? config.options.animation : {}

  config.options.animation = {
    ...existing,
    duration: existing.duration ?? (doughnut ? 720 : 780),
    easing: existing.easing || "easeOutQuart",
    delay(ctx) {
      if (typeof existing.delay === "function") return existing.delay(ctx)
      if (ctx.type !== "data" || ctx.mode !== "default") return 0
      if (ctx.chart?.$analysesSettled) return 0
      if (doughnut) return (ctx.dataIndex || 0) * 28
      // Line : un seul stagger par série (pas par point — sinon ça fige).
      if (lineLike) return (ctx.datasetIndex || 0) * 100
      return (ctx.dataIndex || 0) * 12 + (ctx.datasetIndex || 0) * 50
    },
    onComplete: markChartSettled,
    ...(doughnut ? { animateRotate: true, animateScale: true } : {})
  }

  // Line / mixtes : faire monter la courbe depuis 0 (sinon souvent invisible).
  if (lineLike) {
    config.options.animations = {
      ...(config.options.animations || {}),
      x: { duration: 0 },
      y: {
        type: "number",
        easing: "easeOutQuart",
        duration: 780,
        from: yPixelFromZero
      }
    }
  }

  config.options.transitions = {
    ...(config.options.transitions || {}),
    active: {
      animation: { duration: 180, easing: "easeOutQuad" }
    },
    // Pas d'anim au resize (évite le rejeu quand le layout se stabilise).
    resize: {
      animation: { duration: 0 }
    }
  }
}

function buildConfig(raw) {
  const config = JSON.parse(JSON.stringify(raw))
  const centerLines = config._centerText
  delete config._centerText

  config.options = config.options || {}
  config.options.plugins = config.options.plugins || {}

  if (centerLines?.length) {
    config.plugins = [centerTextPlugin]
    config.options.plugins.analysesCenterText = { lines: centerLines }
  }

  roundDatasetValues(config)
  applyIntegerAxisTicks(config)
  applyTooltipStyle(config)
  applyAnimations(config)

  const moneyDoughnut = Array.isArray(centerLines) &&
    centerLines.some((line) => /€|HT|TTC/.test(String(line)))
  const moneyAxes = axisLooksLikeMoney(config)
  const moneyDataset = (config.data?.datasets || []).some((dataset) =>
    /€|CA/.test(String(dataset.label || ""))
  )
  const moneyChart = moneyDoughnut || moneyAxes || moneyDataset

  // Les barres catalogue / quantités → entiers sans €.
  const quantityBar = config.type === "bar" && !moneyAxes && !moneyDataset

  const existingTooltip = config.options.plugins.tooltip
  config.options.plugins.tooltip = {
    ...existingTooltip,
    callbacks: {
      ...(existingTooltip.callbacks || {}),
      label(context) {
        const datasetLabel = context.dataset?.label || ""
        const sliceLabel = context.label || ""
        // Barres horizontales (indexAxis: y) → valeur dans parsed.x
        const rawValue = context.parsed?.x ?? context.parsed?.y ?? context.parsed ?? context.raw
        const value = typeof rawValue === "object" ? (rawValue?.x ?? rawValue?.y) : rawValue
        if (value == null || Number.isNaN(Number(value))) {
          return datasetLabel || sliceLabel
        }

        // Dataset € / CA en priorité (doughnut double anneau qté + CA).
        if (/€|CA|panier/i.test(datasetLabel)) {
          const name = sliceLabel || datasetLabel
          return name ? `${name}: ${formatEuro(value)}` : formatEuro(value)
        }

        if (/quantit/i.test(datasetLabel)) {
          const name = sliceLabel || datasetLabel
          return name ? `${name}: ${formatInteger(value)}` : formatInteger(value)
        }

        if (quantityBar || (config.type === "doughnut" && !moneyDoughnut)) {
          const name = sliceLabel || datasetLabel
          return name ? `${name}: ${formatInteger(value)}` : formatInteger(value)
        }

        // Ratios non monétaires (ex. art. / commande) même si un axe € existe.
        if (/art\.|articles\s*\/|qté|quantit/i.test(datasetLabel)) {
          const formatted = Number(value).toLocaleString("fr-FR", {
            maximumFractionDigits: 1
          })
          return datasetLabel ? `${datasetLabel}: ${formatted}` : formatted
        }

        if (moneyChart || moneyDoughnut) {
          const name = config.type === "doughnut" ? sliceLabel : datasetLabel
          return name ? `${name}: ${formatEuro(value)}` : formatEuro(value)
        }

        const name = datasetLabel || sliceLabel
        return name ? `${name}: ${formatInteger(value)}` : formatInteger(value)
      }
    }
  }

  return config
}

export function destroyAnalysesCharts(root = document) {
  root.querySelectorAll("canvas[data-analyses-chart]").forEach((canvas) => {
    if (canvas._analysesChart) {
      canvas._analysesChart.destroy()
      canvas._analysesChart = null
    }
  })
}

export function mountAnalysesCharts(root = document) {
  if (typeof Chart === "undefined") return

  destroyAnalysesCharts(root)

  root.querySelectorAll("canvas[data-analyses-chart]").forEach((canvas) => {
    try {
      const raw = JSON.parse(canvas.dataset.analysesChart)
      const config = buildConfig(raw)
      // Parent .analyses-chart-box porte la hauteur ; Chart.js doit le respecter.
      if (config.options?.maintainAspectRatio === false) {
        config.options.resizeDelay = 0
      }
      canvas._analysesChart = new Chart(canvas, config)
    } catch (e) {
      console.error("Analyses chart mount failed", e)
    }
  })
}

// turbo:load couvre aussi le 1er chargement — éviter DOMContentLoaded (double montage / anim rejouée).
document.addEventListener("turbo:load", () => mountAnalysesCharts())
document.addEventListener("turbo:before-cache", () => destroyAnalysesCharts())
if (!window.Turbo) {
  document.addEventListener("DOMContentLoaded", () => mountAnalysesCharts())
}
