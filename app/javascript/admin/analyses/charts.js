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
        const rawValue = context.parsed?.y ?? context.parsed ?? context.raw
        const value = typeof rawValue === "object" ? rawValue?.y : rawValue
        if (value == null || Number.isNaN(Number(value))) {
          return datasetLabel || sliceLabel
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

        if (moneyChart || moneyDoughnut || /€|panier|CA/i.test(datasetLabel)) {
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

document.addEventListener("turbo:load", () => mountAnalysesCharts())
document.addEventListener("turbo:before-cache", () => destroyAnalysesCharts())
document.addEventListener("DOMContentLoaded", () => mountAnalysesCharts())
