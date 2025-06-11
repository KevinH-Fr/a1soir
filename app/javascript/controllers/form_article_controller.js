import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["prixvente_initial", "prixlocation_initial", "caution_initial",
    "type", "location", "vente", "prix", "quantite", "total", "caution", "is_new_article", "coef_longue_duree", "longueduree"]
  
  connect() {
    this.checkIfNew();
  }

  setInitialPrice() {

    const prixventeInitialValue = this.prixvente_initialTarget.value;
    const prixlocationInitialValue = this.prixlocation_initialTarget.value;
    const cautionInitialValue = this.caution_initialTarget.value;

    const location = this.locationTarget.checked;
    const vente = this.venteTarget.checked;

    if (location) {
      this.prixTarget.value =  prixlocationInitialValue;
      this.cautionTarget.value = cautionInitialValue; 

    } else if (vente) {
      this.prixTarget.value =  prixventeInitialValue;
      this.cautionTarget.value = 0;
    }

    const quantiteValue = this.quantiteTarget.value;
    if (quantiteValue == 0) {
      this.quantiteTarget.value = 1;
    }

    this.calculTotal();
  }

  checkIfNew() {
    const isNewArticle = this.is_new_articleTarget.value === "true";

    if (isNewArticle) {
      this.setInitialPrice();
    }
  }

  calculTotal() {
    const prixventeInitialValue = this.prixvente_initialTarget.value;
    const quantiteValue = this.quantiteTarget.value;
    const prixValue = this.prixTarget.value;
    const cautionInitialValue = this.caution_initialTarget.value;
    
    const cautionEditedValue = this.cautionTarget.value;
    console.log("caution edited: ", cautionEditedValue);

    const location = this.locationTarget.checked;
    const vente = this.venteTarget.checked;

    this.totalTarget.value = quantiteValue * prixValue;

    if (location) {
      // if (cautionInitialValue > 0) {
      //   this.cautionTarget.value = quantiteValue * cautionEditedValue;
      // } else {
        this.cautionTarget.value = quantiteValue * cautionEditedValue;
     // }

     // verif si pas d'autres bugs, corriger le pb sur quantité pas parfait
    } else if (vente) {
      this.cautionTarget.value = 0;
    }

  }

  changePrixLongueDuree() {

    const coefLongueDuree = this.coef_longue_dureeTarget.value;
    const longueduree = this.longuedureeTarget.checked;

    console.log("change longue duree");

    if (longueduree) {
      this.prixTarget.value = parseFloat(this.prixTarget.value) * ( 1 + (parseFloat(coefLongueDuree) / 100) ) ; 
    }  else {
      this.prixTarget.value =  parseFloat(this.prixTarget.value) / ( 1 + (parseFloat(coefLongueDuree) / 100) ) ; 
    }

    this.calculTotal();

  }

}
