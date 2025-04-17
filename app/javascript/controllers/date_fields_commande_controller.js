import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["debutloc", "finloc"];

  updateDateFin() {
    const debut = new Date(this.debutlocTarget.value);

    if (!isNaN(debut.getTime())) {
      const year = debut.getFullYear();
      const month = String(debut.getMonth() + 1).padStart(2, '0');
      const day = String(debut.getDate()).padStart(2, '0');

      const minDate = `${year}-${month}-${day}`;

      // Applique la contrainte sur finloc
      this.finlocTarget.min = minDate;

      // Optionnel : vider finloc si elle est antérieure à debutloc
      if (this.finlocTarget.value && this.finlocTarget.value < minDate) {
        this.finlocTarget.value = '';
      }
    }
  }
}
