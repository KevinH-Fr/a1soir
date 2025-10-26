/**
 * Animation simple et élégante au scroll
 * Apparition et disparition progressive des éléments
 */
class ScrollReveal {
  constructor() {
    this.elements = document.querySelectorAll('[data-scroll-reveal]');
    if (this.elements.length === 0) return;
    
    this.init();
  }

  init() {
    // Configuration de l'IntersectionObserver
    const options = {
      root: null,
      rootMargin: '0px',
      threshold: 0.1 // Déclenche quand 10% de l'élément est visible
    };

    // Créer l'observer
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          // L'élément entre dans le viewport - Fondu entrant
          entry.target.classList.add('is-revealed');
        } else {
          // L'élément sort du viewport - Fondu sortant (animation qui se répète)
          entry.target.classList.remove('is-revealed');
        }
      });
    }, options);

    // Observer tous les éléments
    this.elements.forEach(element => {
      this.observer.observe(element);
    });
  }

  destroy() {
    if (this.observer) {
      this.observer.disconnect();
      this.observer = null;
    }
  }
}

// Instance globale
let scrollRevealInstance = null;

/**
 * Initialiser ScrollReveal
 */
function initScrollReveal() {
  // Nettoyer l'ancienne instance
  if (scrollRevealInstance) {
    scrollRevealInstance.destroy();
    scrollRevealInstance = null;
  }

  // Créer la nouvelle instance
  scrollRevealInstance = new ScrollReveal();
}

// Nettoyer avant de quitter la page
document.addEventListener('turbo:before-render', () => {
  if (scrollRevealInstance) {
    scrollRevealInstance.destroy();
    scrollRevealInstance = null;
  }
});

// Initialisation avec Turbo
document.addEventListener('turbo:load', initScrollReveal);

// Initialisation sans Turbo (chargement initial)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initScrollReveal);
} else {
  initScrollReveal();
}

export { ScrollReveal };

