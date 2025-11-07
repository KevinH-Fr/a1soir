/**
 * Carousel de cards contrôlé par le scroll
 * Défilement simple de droite à gauche
 */
class ScrollCardsCarousel {
  constructor() {
    this.carousel = document.querySelector('.scroll-cards-carousel');
    this.container = document.querySelector('.scroll-cards-container');
    this.cards = document.querySelectorAll('.scroll-card');
    
    if (!this.carousel || !this.container || this.cards.length === 0) return;
    
    this.isInView = false;
    this.cardSpacing = 600; // Distance entre les cartes
    this.handleScrollBound = this.handleScroll.bind(this);
    
    this.init();
  }

  init() {
    // Cacher le container au départ
    this.container.style.opacity = '0';
    this.container.style.visibility = 'hidden';
    
    // Initialiser toutes les cards
    this.cards.forEach((card) => {
      card.style.transition = 'all 0.6s cubic-bezier(0.4, 0.0, 0.2, 1)';
      card.style.left = '0';
      card.style.top = '0';
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
    // Ajouter un offset pour retarder le début de l'animation
    const scrolled = Math.max(0, windowHeight - carouselRect.top);
    const scrollableHeight = carouselRect.height;
    const rawProgress = scrolled / scrollableHeight;
    
    // Retarder l'apparition : ne commence qu'après 15% de scroll dans le carousel
    const animationStartOffset = 0.15;
    const progress = rawProgress < animationStartOffset 
      ? 0 
      : Math.min(1, (rawProgress - animationStartOffset) / (1 - animationStartOffset));
    
    // Fade out en fin de carousel (derniers 10%)
    if (progress > 0.9) {
      const fadeProgress = (progress - 0.9) / 0.1;
      this.container.style.opacity = (1 - fadeProgress).toString();
    } else {
      this.container.style.opacity = '1';
    }
    
    // Calculer la position de chaque carte avec animation individuelle
    const numCards = this.cards.length;
    const segmentSize = 1 / numCards; // Chaque carte a sa propre fenêtre de scroll
    
    this.cards.forEach((card, index) => {
      // Calculer la progression pour cette carte spécifique
      const cardStart = index * segmentSize;
      const cardEnd = (index + 1) * segmentSize;
      const cardProgress = Math.max(0, Math.min(1, (progress - cardStart) / (cardEnd - cardStart)));
      
      // Phases pour chaque carte :
      // - 0% à 20% : Entrée (droite → centre)
      // - 20% à 80% : Pause au centre
      // - 80% à 100% : Sortie (centre → gauche)
      const entryEnd = 0.2;
      const exitStart = 0.8;
      
      // Calculer la position relative au conteneur
      const containerRect = this.container.getBoundingClientRect();
      const cardWidth = card.offsetWidth || 450;
      const cardHeight = card.offsetHeight || 600;
      const containerWidth = containerRect.width;
      
      // Position centrée : le centre de la carte doit être au centre du conteneur
      // Pour centrer : (largeur conteneur - largeur carte) / 2
      const centerCardX = (containerWidth - cardWidth) / 2;
      const centerCardY = -(cardHeight / 2);
      
      // Positions de départ et de fin par rapport au conteneur
      const startX = containerWidth + cardWidth; // Commence hors écran à droite
      const endX = -cardWidth; // Sort hors écran à gauche
      
      let desiredX, opacity, scale, zIndex;
      
      if (cardProgress < entryEnd) {
        // Phase d'entrée : droite → centre
        const entryProgress = cardProgress / entryEnd;
        desiredX = startX + (centerCardX - startX) * entryProgress;
        opacity = entryProgress;
        scale = 0.85 + (entryProgress * 0.15); // De 0.85 à 1.0
        zIndex = Math.round(entryProgress * 10);
      } else if (cardProgress < exitStart) {
        // Phase de pause : reste au centre
        desiredX = centerCardX;
        opacity = 1;
        scale = 1;
        zIndex = 10;
      } else {
        // Phase de sortie : centre → gauche
        const exitProgress = (cardProgress - exitStart) / (1 - exitStart);
        desiredX = centerCardX + (endX - centerCardX) * exitProgress;
        opacity = 1 - exitProgress;
        scale = 1 - (exitProgress * 0.15); // De 1.0 à 0.85
        zIndex = Math.round((1 - exitProgress) * 10);
      }
      
      // Appliquer les transformations
      const compensatedTranslateX = desiredX / scale;
      const compensatedTranslateY = centerCardY / scale;
      card.style.transform = `translate(${compensatedTranslateX}px, ${compensatedTranslateY}px) scale(${scale})`;
      card.style.opacity = opacity.toString();
      card.style.zIndex = zIndex;
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
