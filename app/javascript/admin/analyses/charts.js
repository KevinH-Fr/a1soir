function formatEuro(value) {
  if (value == null || Number.isNaN(Number(value))) return ""
  return `${Math.round(Number(value)).toLocaleString("fr-FR")} €`
}

function formatInteger(value) {
  if (value == null || Number.isNaN(Number(value))) return ""
  return Math.round(Number(value)).toLocaleString("fr-FR")
}

function slicePercent(value, data) {
  const total = (data || []).reduce((sum, v) => sum + Number(v || 0), 0)
  if (!total) return 0
  return Math.round((Number(value) / total) * 100)
}

function parsedValue(context) {
  const parsed = context.parsed
  if (parsed == null || typeof parsed !== "object") {
    return parsed ?? context.raw
  }

  // Barres horizontales : la métrique est sur x. Lignes / barres verticales : sur y.
  // (Ne pas faire parsed.x ?? parsed.y : x = index du jour → même valeur pour toutes les séries.)
  const horizontalBar = context.chart?.options?.indexAxis === "y"
  if (horizontalBar) {
    return parsed.x ?? context.raw
  }
  return parsed.y ?? context.raw
}

let chartDefaultsReady = false

function ensureChartDefaults() {
  if (chartDefaultsReady || typeof Chart === "undefined") return
  Chart.defaults.plugins.tooltip = {
    ...(Chart.defaults.plugins.tooltip || {}),
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
  chartDefaultsReady = true
}

function prefersReducedMotion() {
  return typeof window !== "undefined" &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches
}

function axisPixelFromZero(ctx, axisKey, fallbackId) {
  if (ctx.type !== "data") return
  if (ctx.mode !== "default" || ctx.chart?.$analysesSettled) return
  const scaleId = ctx.dataset?.[axisKey] || fallbackId
  const scale = ctx.chart?.scales?.[scaleId]
  if (!scale || typeof scale.getPixelForValue !== "function") return
  return scale.getPixelForValue(0)
}

function markChartSettled(animation) {
  const chart = animation?.chart
  if (!chart || chart.$analysesSettled) return
  chart.$analysesSettled = true
}

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
  const horizontalBar = config.type === "bar" && config.options?.indexAxis === "y"
  const lineLike = !doughnut && (
    config.type === "line" ||
    (config.data?.datasets || []).some((ds) => ds.type === "line")
  )

  config.options.animation = {
    duration: doughnut ? 720 : 780,
    easing: "easeOutQuart",
    delay(ctx) {
      if (ctx.type !== "data" || ctx.mode !== "default" || ctx.chart?.$analysesSettled) return 0
      if (doughnut) return (ctx.dataIndex || 0) * 32
      if (lineLike) return (ctx.datasetIndex || 0) * 100
      if (horizontalBar) return (ctx.dataIndex || 0) * 45 + (ctx.datasetIndex || 0) * 90
      return (ctx.dataIndex || 0) * 12 + (ctx.datasetIndex || 0) * 50
    },
    onComplete: markChartSettled,
    ...(doughnut ? { animateRotate: true, animateScale: true } : {})
  }

  if (lineLike) {
    config.options.animations = {
      x: { duration: 0 },
      y: {
        type: "number",
        easing: "easeOutQuart",
        duration: 780,
        from: (ctx) => axisPixelFromZero(ctx, "yAxisID", "y")
      }
    }
  }

  if (horizontalBar) {
    config.options.animations = {
      y: { duration: 0 },
      x: {
        type: "number",
        easing: "easeOutQuart",
        duration: 780,
        from: (ctx) => axisPixelFromZero(ctx, "xAxisID", "x")
      }
    }
  }

  config.options.transitions = {
    active: { animation: { duration: 180, easing: "easeOutQuad" } },
    resize: { animation: { duration: 0 } }
  }
}

function tooltipLabel(context, tooltipKind, grain) {
  const datasetLabel = context.dataset?.label || ""
  const sliceLabel = context.label || ""
  const value = parsedValue(context)
  if (value == null || Number.isNaN(Number(value))) return datasetLabel || sliceLabel

  const isPctLabel = /\(%\)|part\s+e-shop|taux\s+d['’]?encaissement/i.test(datasetLabel)
  const isMoneyLabel = /€|CA|panier|boutique|e-shop|stripe|encaiss|transaction|non encaissé/i.test(datasetLabel) && !isPctLabel
  const isQtyLabel = /quantit|commandes|^articles$|art\.|articles\s*\//i.test(datasetLabel)
  const periodShareLabel = grain === "hour" ? "% de l'heure" : "% du jour"

  if (tooltipKind === "locvente_qty" || tooltipKind === "locvente_money") {
    const pct = slicePercent(value, context.dataset?.data)
    const body = tooltipKind === "locvente_money" ? formatEuro(value) : formatInteger(value)
    const name = sliceLabel || datasetLabel
    return name ? `${name}: ${body} · ${pct}%` : `${body} · ${pct}%`
  }

  if (tooltipKind === "channels_money") {
    const idx = context.dataIndex
    const datasets = context.chart?.data?.datasets || []
    const dayTotal = datasets.reduce((sum, ds) => {
      const v = Number(ds?.data?.[idx])
      return sum + (Number.isFinite(v) ? v : 0)
    }, 0)
    const pct = dayTotal > 0 ? Math.round((Number(value) / dayTotal) * 100) : 0
    const name = datasetLabel || "Canal"
    return `${name}: ${formatEuro(value)} · ${pct} ${periodShareLabel}`
  }

  if (isPctLabel) {
    const formatted = Number(value).toLocaleString("fr-FR", { maximumFractionDigits: 1 })
    return datasetLabel ? `${datasetLabel}: ${formatted} %` : `${formatted} %`
  }

  if (tooltipKind === "money" || (tooltipKind === "mixed" && isMoneyLabel)) {
    // Doughnut : libellé de part. Barres groupées (vendeur / type) : série (CA, Transactions…).
    const name = context.chart?.config?.type === "doughnut"
      ? (sliceLabel || datasetLabel)
      : datasetLabel
    if (context.chart?.config?.type === "doughnut") {
      const pct = slicePercent(value, context.dataset?.data)
      return name ? `${name}: ${formatEuro(value)} · ${pct}%` : `${formatEuro(value)} · ${pct}%`
    }
    return name ? `${name}: ${formatEuro(value)}` : formatEuro(value)
  }

  if (tooltipKind === "integer" || (tooltipKind === "mixed" && isQtyLabel && !isMoneyLabel)) {
    if (/art\.|articles\s*\//i.test(datasetLabel)) {
      const formatted = Number(value).toLocaleString("fr-FR", { maximumFractionDigits: 1 })
      return datasetLabel ? `${datasetLabel}: ${formatted}` : formatted
    }
    const name = context.chart?.config?.type === "doughnut"
      ? (sliceLabel || datasetLabel)
      : datasetLabel
    return name ? `${name}: ${formatInteger(value)}` : formatInteger(value)
  }

  // mixed / auto fallback
  if (isMoneyLabel) {
    return datasetLabel ? `${datasetLabel}: ${formatEuro(value)}` : formatEuro(value)
  }
  const name = datasetLabel || sliceLabel
  return name ? `${name}: ${formatInteger(value)}` : formatInteger(value)
}

function buildConfig(raw) {
  const config = JSON.parse(JSON.stringify(raw))
  const tooltipKind = config._tooltip || "mixed"
  const grain = config._grain || "day"
  delete config._tooltip
  delete config._grain

  config.options = config.options || {}
  config.options.plugins = config.options.plugins || {}

  applyAnimations(config)

  const existingTooltip = config.options.plugins.tooltip || {}
  config.options.plugins.tooltip = {
    ...existingTooltip,
    callbacks: {
      ...(existingTooltip.callbacks || {}),
      label(context) {
        return tooltipLabel(context, tooltipKind, grain)
      }
    }
  }

  return config
}

export function destroyAnalysesCharts(root = document) {
  root.querySelectorAll("canvas[data-analyses-chart]").forEach((canvas) => {
    if (canvas._analysesChartObserver) {
      canvas._analysesChartObserver.disconnect()
      canvas._analysesChartObserver = null
    }
    if (canvas._analysesChart) {
      canvas._analysesChart.destroy()
      canvas._analysesChart = null
    }
  })
}

export function updateAnalysesChartFromRaw(canvas, rawConfig) {
  if (typeof Chart === "undefined" || !rawConfig) return

  ensureChartDefaults()
  const config = buildConfig(rawConfig)

  if (canvas._analysesChart) {
    const chart = canvas._analysesChart
    chart.$analysesSettled = true
    chart.data = config.data
    chart.options = config.options
    chart.config._tooltip = rawConfig._tooltip
    chart.update("none")
    return
  }

  canvas.dataset.analysesChart = JSON.stringify(rawConfig)
  mountChartWhenVisible(canvas, config)
}

function createAnalysesChart(canvas, config) {
  if (canvas._analysesChart) return
  if (config.options?.maintainAspectRatio === false) {
    config.options.resizeDelay = 0
  }
  canvas._analysesChart = new Chart(canvas, config)
}

function mountChartWhenVisible(canvas, config) {
  if (prefersReducedMotion() || typeof IntersectionObserver === "undefined") {
    createAnalysesChart(canvas, config)
    return
  }

  const target = canvas.closest(".analyses-chart-box") || canvas
  const rect = target.getBoundingClientRect()
  const vh = window.innerHeight || document.documentElement.clientHeight
  const vw = window.innerWidth || document.documentElement.clientWidth
  const alreadyVisible = rect.bottom > 0 && rect.top < vh && rect.right > 0 && rect.left < vw

  if (alreadyVisible) {
    createAnalysesChart(canvas, config)
    return
  }

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return
        observer.disconnect()
        canvas._analysesChartObserver = null
        createAnalysesChart(canvas, config)
      })
    },
    { root: null, rootMargin: "80px 0px", threshold: 0.12 }
  )

  canvas._analysesChartObserver = observer
  observer.observe(target)
}

export function mountAnalysesCharts(root = document) {
  if (typeof Chart === "undefined") return
  ensureChartDefaults()
  destroyAnalysesCharts(root)

  root.querySelectorAll("canvas[data-analyses-chart]").forEach((canvas) => {
    try {
      const config = buildConfig(JSON.parse(canvas.dataset.analysesChart))
      mountChartWhenVisible(canvas, config)
    } catch (e) {
      console.error("Analyses chart mount failed", e)
    }
  })
}

document.addEventListener("turbo:load", () => mountAnalysesCharts())
document.addEventListener("turbo:before-cache", () => destroyAnalysesCharts())
if (!window.Turbo) {
  document.addEventListener("DOMContentLoaded", () => mountAnalysesCharts())
}
