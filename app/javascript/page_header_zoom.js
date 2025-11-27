/**
 * Effet de zoom sur les images du page_header au scroll
 */
class PageHeaderZoom {
  constructor() {
    this.containers = document.querySelectorAll('.page-header-container');
    if (this.containers.length === 0) return;
    
    this.init();
  }

  init() {
    this.handleScrollBound = this.handleScroll.bind(this);
    this.scrollScales = new Map(); // Stocker les scales du scroll pour chaque image
    window.addEventListener('scroll', this.handleScrollBound, { passive: true });
    // Appeler une première fois pour l'état initial
    requestAnimationFrame(() => this.handleScroll());
    // Ajouter les événements hover
    this.setupHover();
  }

  setupHover() {
    this.containers.forEach(container => {
      const images = container.querySelectorAll('[data-page-header-image]');
      images.forEach(image => {
        image.addEventListener('mouseenter', () => {
          const scrollScale = this.scrollScales.get(image) || 1;
          const hoverScale = 1.05;
          image.style.transform = `scale(${scrollScale * hoverScale})`;
        });
        
        image.addEventListener('mouseleave', () => {
          const scrollScale = this.scrollScales.get(image) || 1;
          image.style.transform = `scale(${scrollScale})`;
        });
      });
    });
  }

  handleScroll() {
    this.containers.forEach(container => {
      const images = container.querySelectorAll('[data-page-header-image]');
      if (images.length === 0) return;

      const rect = container.getBoundingClientRect();
      const windowHeight = window.innerHeight;
      const containerHeight = rect.height;
      
      // Calculer la position du scroll par rapport au container
      // Quand le container entre dans le viewport, on commence le zoom
      const containerTop = rect.top;
      const containerBottom = rect.bottom;
      
      // Zone de scroll active : du moment où le container entre dans le viewport
      // jusqu'à ce qu'il sorte complètement
      if (containerTop < windowHeight && containerBottom > 0) {
        // Calculer la progression du scroll dans le container
        // 0 = container en haut du viewport, 1 = container complètement sorti
        const scrollProgress = Math.max(0, Math.min(1, 
          (windowHeight - containerTop) / (windowHeight + containerHeight)
        ));
        
        // Effet de zoom : zoom progressif de 1 à 1.3 pendant le scroll
        const minScale = 1;
        const maxScale = 1.3;
        const scale = minScale + (maxScale - minScale) * scrollProgress;
        
        // Appliquer le zoom à toutes les images
        images.forEach(image => {
          // Stocker le scale du scroll
          this.scrollScales.set(image, scale);
          // Appliquer le transform seulement si pas de hover actif
          if (!image.matches(':hover')) {
            image.style.transform = `scale(${scale})`;
          }
        });
      } else if (containerTop >= windowHeight) {
        // Container pas encore visible : pas de zoom
        images.forEach(image => {
          this.scrollScales.set(image, 1);
          if (!image.matches(':hover')) {
            image.style.transform = 'scale(1)';
          }
        });
      } else {
        // Container complètement passé : zoom maximum
        images.forEach(image => {
          this.scrollScales.set(image, 1.3);
          if (!image.matches(':hover')) {
            image.style.transform = 'scale(1.3)';
          }
        });
      }
    });
  }

  destroy() {
    window.removeEventListener('scroll', this.handleScrollBound);
  }
}

// Instance globale
let pageHeaderZoomInstance = null;

/**
 * Initialiser PageHeaderZoom
 */
function initPageHeaderZoom() {
  // Nettoyer l'ancienne instance
  if (pageHeaderZoomInstance) {
    pageHeaderZoomInstance.destroy();
    pageHeaderZoomInstance = null;
  }

  // Créer la nouvelle instance
  pageHeaderZoomInstance = new PageHeaderZoom();
}

// Nettoyer avant de quitter la page
document.addEventListener('turbo:before-render', () => {
  if (pageHeaderZoomInstance) {
    pageHeaderZoomInstance.destroy();
    pageHeaderZoomInstance = null;
  }
});

// Initialisation avec Turbo
document.addEventListener('turbo:load', initPageHeaderZoom);

// Initialisation sans Turbo (chargement initial)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initPageHeaderZoom);
} else {
  initPageHeaderZoom();
}

export { PageHeaderZoom };

