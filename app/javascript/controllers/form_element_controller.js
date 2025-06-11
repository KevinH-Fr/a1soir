import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-element"
export default class extends Controller {
  static targets = ["submitbtn"]
  connect() {
    this.submitbtnTarget.hidden = true
   // console.log("connect btn submit");

  }

  remotesubmit() {
    this.submitbtnTarget.click()
//    console.log("click btn submit");
  }
}