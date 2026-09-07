import { Controller } from "@hotwired/stimulus"
import { syncMensurationShellGuided, syncMensurationStepUrl } from "../mensuration/step_url"

// Met à jour l'URL (et le mode guidé) à chaque rendu du turbo-frame d'étape.
export default class extends Controller {
  connect() {
    syncMensurationStepUrl(this.element)
    syncMensurationShellGuided(this.element)
  }
}
