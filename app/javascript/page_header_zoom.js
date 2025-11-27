/**
 * Effet de zoom sur les images du page_header et du carousel au scroll
 */
class PageHeaderZoom {
  constructor() {
    this.pageHeaderContainers = document.querySelectorAll('.page-header-container');
    this.carouselContainers = document.querySelectorAll('#heroCarousel');
    this.containers = [...this.pageHeaderContainers, ...this.carouselContainers];
    if (this.containers.length === 0) return;
    
    this.init();
  }

  init() {
    this.handleScrollBound = this.handleScroll.bind(this);
    this.scrollScales = new Map(); // Stocker les scales du scroll pour chaque image
    
    // Initialiser les scales pour tous les éléments
    this.containers.forEach(container => {
      const pageHeaderImages = container.querySelectorAll('[data-page-header-image]');
      const carouselMedia = container.querySelectorAll('[data-carousel-media]');
      const allMedia = [...pageHeaderImages, ...carouselMedia];
      allMedia.forEach(media => {
        this.scrollScales.set(media, 1);
      });
    });
    
    window.addEventListener('scroll', this.handleScrollBound, { passive: true });
    // Appeler une première fois pour l'état initial
    requestAnimationFrame(() => this.handleScroll());
    // Ajouter les événements hover
    this.setupHover();
  }

  setupHover() {
    this.containers.forEach(container => {
      // Images du page_header
      const pageHeaderImages = container.querySelectorAll('[data-page-header-image]');
      // Images/vidéos du carousel
      const carouselMedia = container.querySelectorAll('[data-carousel-media]');
      const allMedia = [...pageHeaderImages, ...carouselMedia];
      
      allMedia.forEach(media => {
        // Initialiser le scale si pas encore défini
        if (!this.scrollScales.has(media)) {
          this.scrollScales.set(media, 1);
        }
        
        const handleMouseEnter = () => {
          const scrollScale = this.scrollScales.get(media) || 1;
          const hoverScale = 1.02;
          media.style.transform = `scale(${scrollScale * hoverScale})`;
        };
        
        const handleMouseLeave = () => {
          const scrollScale = this.scrollScales.get(media) || 1;
          media.style.transform = `scale(${scrollScale})`;
        };
        
        media.addEventListener('mouseenter', handleMouseEnter);
        media.addEventListener('mouseleave', handleMouseLeave);
      });
    });
  }

  handleScroll() {
    this.containers.forEach(container => {
      // Images du page_header
      const pageHeaderImages = container.querySelectorAll('[data-page-header-image]');
      // Images/vidéos du carousel
      const carouselMedia = container.querySelectorAll('[data-carousel-media]');
      const allMedia = [...pageHeaderImages, ...carouselMedia];
      
      if (allMedia.length === 0) return;

      const rect = container.getBoundingClientRect();
      const windowHeight = window.innerHeight;
      const containerHeight = rect.height;
      
      // Calculer la position du scroll par rapport au container
      // Quand le container entre dans le viewport, on commence le zoom
      const containerTop = rect.top;
      const containerBottom = rect.bottom;
      
      // Pour le carousel, on applique toujours l'effet si visible
      // Pour le page_header, on suit le scroll normalement
      const isCarousel = container.id === 'heroCarousel';
      
      if (isCarousel) {
        // Pour le carousel : zoom léger constant si visible
        // Initialiser le scale à 1 si pas encore défini
        allMedia.forEach(media => {
          if (!this.scrollScales.has(media)) {
            this.scrollScales.set(media, 1);
          }
        });
        
        if (containerTop < windowHeight && containerBottom > 0) {
          const scrollProgress = Math.max(0, Math.min(1, 
            (windowHeight - containerTop) / (windowHeight + containerHeight)
          ));
          const minScale = 1;
          const maxScale = 1.1; // Zoom plus fin pour le carousel
          const scale = minScale + (maxScale - minScale) * scrollProgress;
          
          allMedia.forEach(media => {
            this.scrollScales.set(media, scale);
            if (!media.matches(':hover')) {
              media.style.transform = `scale(${scale})`;
            }
          });
        } else {
          // Carousel hors viewport : scale à 1
          allMedia.forEach(media => {
            this.scrollScales.set(media, 1);
            if (!media.matches(':hover')) {
              media.style.transform = 'scale(1)';
            }
          });
        }
      } else {
        // Pour le page_header : comportement original
        if (containerTop < windowHeight && containerBottom > 0) {
          const scrollProgress = Math.max(0, Math.min(1, 
            (windowHeight - containerTop) / (windowHeight + containerHeight)
          ));
          
          // Effet de zoom : zoom progressif de 1 à 1.3 pendant le scroll
          const minScale = 1;
          const maxScale = 1.3;
          const scale = minScale + (maxScale - minScale) * scrollProgress;
          
          allMedia.forEach(media => {
            this.scrollScales.set(media, scale);
            if (!media.matches(':hover')) {
              media.style.transform = `scale(${scale})`;
            }
          });
        } else if (containerTop >= windowHeight) {
          // Container pas encore visible : pas de zoom
          allMedia.forEach(media => {
            this.scrollScales.set(media, 1);
            if (!media.matches(':hover')) {
              media.style.transform = 'scale(1)';
            }
          });
        } else {
          // Container complètement passé : zoom maximum
          allMedia.forEach(media => {
            this.scrollScales.set(media, 1.3);
            if (!media.matches(':hover')) {
              media.style.transform = 'scale(1.3)';
            }
          });
        }
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

