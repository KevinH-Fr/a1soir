// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./controllers"


import "trix"
import "@rails/actiontext"
import "./three_scene"
import "./dress_model"
import "./home_text_animation"

// require jquery
// require jquery_ujs

document.addEventListener("turbo:load", () => {
    AOS.init();
  });
  