import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autohide"
export default class extends Controller {
  static values = { delay: { type: Number, default: 4000 } }
  
  connect() {
    // Supprimer les anciennes alertes s'il y en a plusieurs
    const allAlerts = document.querySelectorAll('[data-controller="autohide"]')
    const currentKey = this.element.id.match(/flash_(\w+)_/)?.[1]
    if (allAlerts.length > 0 && currentKey) {
      // Garder uniquement la dernière alert de ce type
      const alertsWithSameKey = Array.from(allAlerts).filter(alert => 
        alert.id.includes(`flash_${currentKey}_`)
      )
      if (alertsWithSameKey.length > 1) {
        alertsWithSameKey.forEach((alert, index) => {
          if (index < alertsWithSameKey.length - 1) alert.remove()
        })
      }
    }
    
    this.timeoutId = setTimeout(() => {
      this.dismiss()
    }, this.delayValue)
  }
  
  disconnect() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }
  
  dismiss() {
    this.element.remove()
  }
}
