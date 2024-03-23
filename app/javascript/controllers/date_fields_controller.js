// app/javascript/controllers/date_fields_controller.js

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["datedebut", "datefin", "dureerdv"];

  connect() {
    console.log("Controller date fields connected");
  }
    
  updateDateFin() {
    console.log("Called updateDateFin");
    const datedebutValue = new Date(this.datedebutTarget.value);
    const dureeRdvValue = parseInt(this.dureerdvTarget.value); // Convert value to integer

    // Ensure both dates are valid
    if (!isNaN(datedebutValue.getTime()) && !isNaN(dureeRdvValue)) {
      // Add duration in minutes to the datedebut
      const datefinValue = new Date(datedebutValue.getTime() + ( dureeRdvValue * 120000 )); // Add minutes in milliseconds

      // Format datefin as "YYYY-MM-DDTHH:MM"
      const datefinFormatted = datefinValue.toISOString().slice(0, 16);

      // Set the value of datefin field
      this.datefinTarget.value = datefinFormatted;
    }
  }
}
