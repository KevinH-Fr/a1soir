import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-element"
export default class extends Controller {
  static targets = ["prixvente_initial", "prixlocation_initial", "type", "prix"]
  
  connect() {
    console.log("form article connected");
  //  this.set_initial_price();
  }

  set_initial_price() {
    const prixventeInitialValue = this.prixvente_initialTarget.value;
    const prixlocationInitialValue = this.prixlocation_initialTarget.value;

    const type = this.typeTarget.value;

    console.log("type:" + type  + " - prix vente initial: " + prixventeInitialValue  + 
      " - prix location initial: " + prixlocationInitialValue);

    if (type == "location") {
      this.prixTarget.value = prixlocationInitialValue; 
    } else if (type == "vente") {
      this.prixTarget.value = prixventeInitialValue;
    }

  }

  update_price(){
    console.log("call update prices");
  }

  change_type_locvente(){
    console.log("call change type loc vente");

    const prixventeInitialValue = this.prixvente_initialTarget.value;
    const prixlocationInitialValue = this.prixlocation_initialTarget.value;

    const type = this.typeTarget.value;

    console.log("type:" + type  + " - prix vente initial: " + prixventeInitialValue  + 
      " - prix location initial: " + prixlocationInitialValue);

    if (type == "location") {
      this.prixTarget.value = prixlocationInitialValue; 
    } else if (type == "vente") {
      this.prixTarget.value = prixventeInitialValue;
    }

    
  }
}