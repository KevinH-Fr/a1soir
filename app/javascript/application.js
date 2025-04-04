// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./controllers"


//import "trix"
//import "@rails/actiontext"

// require jquery
// require jquery_ujs

document.addEventListener("turbo:load", () => {
    AOS.init();
  });
  
// Your Three.js scene
import "./three/scene"

//import "./three/scene_test"