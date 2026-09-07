function currentStepKey(frame) {
  if (!frame) return null

  return frame.dataset.mensurationStep
    || frame.querySelector('input[name="step"]')?.value
    || null
}

export function syncMensurationShellGuided(frame = document.getElementById("mensuration_step")) {
  const shell = document.querySelector("[data-mensuration-shell]")
  if (!shell) return

  shell.classList.toggle("mensuration-shell--guided", frame?.classList.contains("mensuration-step--guided"))
}

export function syncMensurationStepUrl(frame = document.getElementById("mensuration_step")) {
  syncMensurationShellGuided(frame)

  const step = currentStepKey(frame)
  if (!step) return

  const url = new URL(window.location.href)
  if (!url.pathname.includes("/m/")) return

  url.searchParams.set("step", step)
  const nextUrl = url.toString()
  if (window.location.href === nextUrl) return

  history.replaceState(history.state, "", nextUrl)
}

export function installMensurationStepUrlSync() {
  document.addEventListener("turbo:frame-render", (event) => {
    if (event.target?.id === "mensuration_step") syncMensurationStepUrl(event.target)
  })

  document.addEventListener("turbo:load", () => syncMensurationStepUrl())
}
