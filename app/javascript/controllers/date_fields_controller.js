// app/javascript/controllers/date_fields_controller.js

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["datedebut", "datefin", "dureerdv"];

  connect() {
  }
    
  updateDateFin() {
    const datedebutValue = new Date(this.datedebutTarget.value);
    const dureeRdvValue = parseInt(this.dureerdvTarget.value); // Convert value to integer
  
    console.log(datedebutValue);
    console.log(dureeRdvValue);
  
    if (!isNaN(datedebutValue.getTime()) && !isNaN(dureeRdvValue)) {
      // Add duration in minutes to the datedebut
      const datefinValue = new Date(datedebutValue.getTime() + (dureeRdvValue * 60000)); // Add minutes in milliseconds
  
      // Manually format datefin as "YYYY-MM-DDTHH:MM" in the local time zone
      const year = datefinValue.getFullYear();
      const month = String(datefinValue.getMonth() + 1).padStart(2, '0'); // Months are zero-indexed
      const day = String(datefinValue.getDate()).padStart(2, '0');
      const hours = String(datefinValue.getHours()).padStart(2, '0');
      const minutes = String(datefinValue.getMinutes()).padStart(2, '0');
  
      const datefinFormatted = `${year}-${month}-${day}T${hours}:${minutes}`;
      
      // Set the value of datefin field
      this.datefinTarget.value = datefinFormatted;
    }
  }
    
}
