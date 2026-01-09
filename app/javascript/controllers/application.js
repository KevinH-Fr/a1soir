import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

// Log pour vérifier que Stimulus est chargé
console.log("🚀 Stimulus Application démarrée")

export { application }
