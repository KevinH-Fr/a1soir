import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["debutloc", "finloc"];

  updateDateFin() {

    const datedebut = new Date(this.debutlocTarget.value);

    if (isNaN(datedebut.getTime())) {
      console.warn("Date de début invalide.");
      return;
    }

    // Calcule la date de fin = date de début + 4 jours
    const dateFinCalculee = new Date(datedebut);
    dateFinCalculee.setDate(dateFinCalculee.getDate() + 4);

    const formattedDateFin = this.formatDate(dateFinCalculee);

    if (!this.finlocTarget.value) {
      this.finlocTarget.value = formattedDateFin;
      return;
    }

    const dateFinExistante = new Date(this.finlocTarget.value);

    if (!isNaN(dateFinExistante.getTime()) && dateFinExistante < datedebut) {
      this.finlocTarget.value = formattedDateFin;
    }
  }

  formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }
}
