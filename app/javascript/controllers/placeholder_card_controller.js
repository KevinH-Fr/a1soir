import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["placeholder", "content"];

  connect() {
    console.log("Stimulus controller placeholder connected");

    // Simulate a loading delay (e.g., 2 seconds)
    setTimeout(() => {
      // Remove the placeholder classes and display the real content
      this.placeholderTargets.forEach((placeholder) => {
        placeholder.classList.remove("placeholder-glow", "placeholder");
      });

      // Show the real content
      this.contentTargets.forEach((content) => {
        content.style.display = "block"; // Show the real content
      });

      // Hide the placeholder card
      this.placeholderTargets.forEach((placeholder) => {
        placeholder.closest('.card').style.display = "none"; // Hide the card containing placeholder
      });
    }, 100); // Simulated delay
  }
}
