/**
 * Carousel de cards contrôlé par le scroll
 * Animation simple : apparition/disparition des cartes
 */
class ScrollCardsCarousel {
  constructor() {
    this.carousel = document.querySelector('.scroll-cards-carousel');
    this.container = document.querySelector('.scroll-cards-container');
    this.cards = document.querySelectorAll('.scroll-card');
    
    if (!this.carousel || !this.container || this.cards.length === 0) return;
    
    this.isInView = false;
    this.handleScrollBound = this.handleScroll.bind(this);
    
    this.init();
  }

  init() {
    // Cacher le container au départ
    this.container.style.opacity = '0';
    this.container.style.visibility = 'hidden';
    
    // Initialiser toutes les cards
    this.cards.forEach((card) => {
      card.style.transition = 'opacity 0.8s ease-in-out';
      card.style.position = 'absolute';
      card.style.top = '50%';
      card.style.left = '50%';
      card.style.transform = 'translate(-50%, -50%)';
      card.style.opacity = '0';
      card.style.width = '100vw';
      card.style.height = '100vh';
      card.style.zIndex = '1';
    });

    // Écouter le scroll
    window.addEventListener('scroll', this.handleScrollBound, { passive: true });
    
    // Vérifier la position initiale
    requestAnimationFrame(() => this.handleScroll());
  }

  handleScroll() {
    if (!this.carousel) return;
    
    // Vérifier si la section discover est encore visible
    const discoverSection = document.querySelector('[data-discover]');
    let discoverVisible = false;
    if (discoverSection) {
      const discoverRect = discoverSection.getBoundingClientRect();
      const windowHeight = window.innerHeight;
      const discoverHeight = discoverRect.height;
      const rawScrollProgress = (windowHeight - discoverRect.top) / (discoverHeight + windowHeight);
      
      // La section discover disparaît complètement à 90% (exitPhaseEnd)
      // On attend qu'elle soit complètement sortie avant d'afficher les cartes
      discoverVisible = rawScrollProgress < 0.95; // Marge de sécurité
    }
    
    const carouselRect = this.carousel.getBoundingClientRect();
    const windowHeight = window.innerHeight;
    
    // Vérifier si on est dans la zone du carousel
    const isInCarousel = carouselRect.top <= windowHeight && carouselRect.bottom > 0;
    
    // Ne pas afficher si la section discover est encore visible
    if (!isInCarousel || discoverVisible) {
      if (this.isInView) {
        this.hideContainer();
      }
      return;
    }
    
    // Afficher le container s'il était caché
    if (!this.isInView) {
      this.showContainer();
      this.isInView = true;
    }
    
    // Calculer la progression du scroll dans la zone du carousel
    const scrolled = Math.max(0, windowHeight - carouselRect.top);
    const scrollableHeight = carouselRect.height;
    const progress = Math.min(1, scrolled / scrollableHeight);
    
    // Fade out en fin de carousel (derniers 5%)
    if (progress > 0.95) {
      const fadeProgress = (progress - 0.95) / 0.05;
      this.container.style.opacity = (1 - fadeProgress).toString();
    } else {
      this.container.style.opacity = '1';
    }
    
    // Calculer quelle carte doit être visible
    const numCards = this.cards.length;
    const segmentSize = 1 / numCards; // Chaque carte occupe une portion égale du scroll
    
    this.cards.forEach((card, index) => {
      // Calculer la progression pour cette carte spécifique
      const cardStart = index * segmentSize;
      const cardEnd = (index + 1) * segmentSize;
      
      // Zone de transition entre les cartes (20% de la zone de chaque carte)
      const transitionZone = segmentSize * 0.2;
      
      let opacity = 0;
      
      if (progress >= cardStart && progress < cardEnd) {
        // Cette carte est dans sa zone de scroll
        const cardProgress = (progress - cardStart) / segmentSize;
        
        if (cardProgress < transitionZone) {
          // Apparition (fade in)
          opacity = cardProgress / transitionZone;
        } else if (cardProgress > (1 - transitionZone)) {
          // Disparition (fade out)
          opacity = (1 - cardProgress) / transitionZone;
        } else {
          // Visible complètement
          opacity = 1;
        }
      }
      
      // Appliquer l'opacité
      card.style.opacity = opacity.toString();
      
      // Mettre la carte active au-dessus
      if (opacity > 0) {
        card.style.zIndex = Math.round(opacity * 10) + 1;
      } else {
        card.style.zIndex = '1';
      }
    });
  }
  
  showContainer() {
    this.container.style.opacity = '1';
    this.container.style.visibility = 'visible';
  }
  
  hideContainer() {
    this.container.style.opacity = '0';
    this.container.style.visibility = 'hidden';
    this.isInView = false;
  }

  destroy() {
    if (this.handleScrollBound) {
      window.removeEventListener('scroll', this.handleScrollBound);
    }
  }
}

// Instance globale
let scrollCardsCarouselInstance = null;

function initScrollCardsCarousel() {
  if (scrollCardsCarouselInstance) {
    scrollCardsCarouselInstance.destroy();
    scrollCardsCarouselInstance = null;
  }

  const carousel = document.querySelector('.scroll-cards-carousel');
  if (carousel) {
    scrollCardsCarouselInstance = new ScrollCardsCarousel();
  }
}

document.addEventListener('turbo:before-render', () => {
  if (scrollCardsCarouselInstance) {
    scrollCardsCarouselInstance.destroy();
    scrollCardsCarouselInstance = null;
  }
});

document.addEventListener('turbo:load', initScrollCardsCarousel);

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initScrollCardsCarousel);
} else {
  initScrollCardsCarousel();
}

export { ScrollCardsCarousel };
