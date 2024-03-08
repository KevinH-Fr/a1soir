import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["prixvente_initial", "prixlocation_initial", 
    "type", "location", "vente", "prix", "quantite", "total", "is_new_article"]
  
  connect() {
    console.log("Form article connected");
    this.checkIfNew();
  }

  setInitialPrice() {
    console.log("Call set initial price");

    const prixventeInitialValue = this.prixvente_initialTarget.value;
    const prixlocationInitialValue = this.prixlocation_initialTarget.value;
 //   const type = this.typeTarget.value;
    const location = this.locationTarget.checked;
    const vente = this.venteTarget.checked;

    console.log("location is:" + location);

    if (location) {
      this.prixTarget.value = prixlocationInitialValue 
      console.log(prixlocationInitialValue);
    } else {
      this.prixTarget.value =  prixventeInitialValue;
      console.log(prixventeInitialValue);
    }


    const quantiteValue = this.quantiteTarget.value;
    if (quantiteValue == 0) {
      this.quantiteTarget.value = 1;
    }

    this.calculTotal();
  }

  checkIfNew() {
    console.log("Call check if new");

    const isNewArticle = this.is_new_articleTarget.value === "true";

    if (isNewArticle) {
      this.setInitialPrice();
    }
  }

  calculTotal() {
    console.log("Call calcul total");

    const quantiteValue = this.quantiteTarget.value;
    const prixValue = this.prixTarget.value;

    this.totalTarget.value = quantiteValue * prixValue;
  }
}
