import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
  }

  handleClick(event) {
    const clickedButton = event.currentTarget;
    const container = clickedButton.closest(".d-flex"); // limiter a div 
  
    if (container) {
      const buttons = container.getElementsByClassName("btn-topic");
  
      for (const button of buttons) {
        if (button === clickedButton) {
          button.classList.add("active");
        } else {
          button.classList.remove("active");
        }
      }
    }
  }
  
}
