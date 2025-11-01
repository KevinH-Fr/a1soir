/**
 * Carousel de cards contrôlé par le scroll - Style manège
 * Les cartes glissent de droite vers gauche avec chevauchement
 */
class ScrollCardsCarousel {
  constructor() {
    this.carousel = document.querySelector('.scroll-cards-carousel');
    this.container = document.querySelector('.scroll-cards-container');
    this.cards = document.querySelectorAll('.scroll-card');
    
    if (!this.carousel || !this.container || this.cards.length === 0) return;
    
    this.isInView = false;
    this.lastVisibleIndex = -1;
    this.cardSpacing = 200; // Distance entre les cartes au centre
    this.exitSpacing = 400; // Distance pour les cartes qui disparaissent
    
    this.init();
  }

  init() {
    // Cacher le container au départ
    this.container.style.opacity = '0';
    this.container.style.visibility = 'hidden';
    this.container.style.transition = 'opacity 0.3s ease, visibility 0.3s ease';
    
    // Initialiser toutes les cards
    this.cards.forEach((card, index) => {
      card.style.opacity = '0';
      card.style.transform = 'translateX(0) scale(0.85)';
      card.style.transition = 'all 1s cubic-bezier(0.4, 0.0, 0.2, 1)';
    });

    // Écouter le scroll
    window.addEventListener('scroll', () => this.handleScroll());
    
    // Vérifier la position initiale
    setTimeout(() => {
      this.handleScroll();
    }, 100);
  }

  handleScroll() {
    const carouselRect = this.carousel.getBoundingClientRect();
    const windowHeight = window.innerHeight;
    
    // Vérifier si on est dans la zone du carousel
    const isInCarousel = carouselRect.top <= 0 && carouselRect.bottom > 0;
    
    if (!isInCarousel) {
      if (this.isInView) {
        this.hideContainer();
      }
      return;
    }
    
    // Afficher le container s'il était caché
    if (!this.isInView) {
      this.showContainer();
    }
    
    this.isInView = true;
    
    // Calculer la progression du scroll dans la zone du carousel
    const scrolled = Math.abs(carouselRect.top);
    const scrollableHeight = carouselRect.height - windowHeight;
    const progress = Math.max(0, Math.min(1, scrolled / scrollableHeight));
    
    // Zone de fade out : les 15% finaux du carousel
    const fadeOutStart = 0.85;
    
    if (progress >= fadeOutStart) {
      const fadeProgress = (progress - fadeOutStart) / (1 - fadeOutStart);
      const opacity = 1 - fadeProgress;
      this.container.style.opacity = Math.max(0, opacity).toString();
      
      if (progress >= 0.98) {
        this.container.style.visibility = 'hidden';
      }
    } else {
      this.container.style.opacity = '1';
      this.container.style.visibility = 'visible';
    }
    
    // Déterminer l'index de la carte au centre
    const numCards = this.cards.length;
    const segmentSize = 1 / numCards;
    const centerCardIndex = Math.floor(progress / segmentSize);
    
    // Afficher les cartes selon leur position dans le manège
    this.cards.forEach((card, index) => {
      const relativeIndex = index - centerCardIndex;
      const cardProgress = (progress % segmentSize) / segmentSize;
      
      let x = 0;
      let scale = 0.85;
      let opacity = 0;
      let zIndex = 0;
      
      if (relativeIndex === 0) {
        // Carte au centre - reste centrée plus longtemps
        // Elle ne commence à bouger qu'après 40% du scroll
        const adjustedProgress = Math.max(0, (cardProgress - 0.4) / 0.6);
        x = -adjustedProgress * this.cardSpacing;
        scale = 1;
        opacity = 1;
        zIndex = 10;
      } else if (relativeIndex === 1) {
        // Carte suivante (à droite) - arrive progressivement
        // Elle commence à apparaître à 40% du scroll
        const adjustedProgress = Math.max(0, (cardProgress - 0.4) / 0.6);
        x = this.cardSpacing - adjustedProgress * this.cardSpacing;
        scale = 0.85;
        opacity = 0.5 + (adjustedProgress * 0.5); // Fade in progressif
        zIndex = 5;
      } else if (relativeIndex === -1) {
        // Carte précédente (à gauche) - disparaît en s'éloignant et rétrécissant
        const exitProgress = cardProgress;
        x = -this.cardSpacing - (exitProgress * this.exitSpacing);
        scale = 0.85 - (exitProgress * 0.5); // Rétrécit de 0.85 à 0.35
        opacity = Math.max(0, 1 - (exitProgress * 1.5)); // Disparaît plus vite
        zIndex = 1;
      } else {
        // Cartes hors vue
        opacity = 0;
        zIndex = 0;
      }
      
      // Appliquer les transformations
      card.style.transform = `translateX(${x}px) scale(${scale})`;
      card.style.opacity = opacity.toString();
      card.style.zIndex = zIndex;
      
      // Ajouter la bordure rose pour la carte au centre
      if (relativeIndex === 0) {
        card.style.borderColor = 'rgba(208, 77, 123, 0.4)';
        card.style.boxShadow = '0 20px 40px rgba(208, 77, 123, 0.25), 0 0 60px rgba(208, 77, 123, 0.15), inset 0 1px 0 rgba(255, 255, 255, 0.1)';
      } else {
        card.style.borderColor = 'rgba(208, 77, 123, 0.15)';
        card.style.boxShadow = '0 8px 32px rgba(0, 0, 0, 0.3), inset 0 1px 0 rgba(255, 255, 255, 0.05)';
      }
      
      // Animer les éléments internes pour la carte au centre
      if (relativeIndex === 0 && this.lastVisibleIndex !== index) {
        this.animateCardEnter(card);
        this.lastVisibleIndex = index;
      } else if (relativeIndex !== 0 && this.lastVisibleIndex === index) {
        this.animateCardExit(card);
        this.lastVisibleIndex = -1;
      }
    });
  }
  
  showContainer() {
    this.container.style.opacity = '1';
    this.container.style.visibility = 'visible';
  }
  
  hideContainer() {
    this.container.style.transition = 'opacity 0.3s ease, visibility 0.3s ease';
    this.container.style.opacity = '0';
    this.container.style.visibility = 'hidden';
    this.isInView = false;
    this.resetCarousel();
  }

  animateCardEnter(card) {
    const icon = card.querySelector('.nav-card-icon');
    const title = card.querySelector('.nav-card-title');
    const description = card.querySelector('.nav-card-description');
    const arrow = card.querySelector('.nav-card-arrow');
    
    [icon, title, description, arrow].forEach(el => {
      if (el) el.classList.remove('animate-out');
    });
    
    if (icon) icon.classList.add('animate-in');
    if (title) title.classList.add('animate-in');
    if (description) description.classList.add('animate-in');
    if (arrow) arrow.classList.add('animate-in');
  }

  animateCardExit(card) {
    const icon = card.querySelector('.nav-card-icon');
    const title = card.querySelector('.nav-card-title');
    const description = card.querySelector('.nav-card-description');
    const arrow = card.querySelector('.nav-card-arrow');
    
    [icon, title, description, arrow].forEach(el => {
      if (el) el.classList.remove('animate-in');
    });
  }

  resetCarousel() {
    this.lastVisibleIndex = -1;
    
    this.cards.forEach(card => {
      card.style.transition = 'all 0.3s ease';
      card.style.opacity = '0';
      card.style.transform = 'translateX(0) scale(0.85)';
      
      const elements = card.querySelectorAll('.nav-card-icon, .nav-card-title, .nav-card-description, .nav-card-arrow');
      elements.forEach(el => {
        el.classList.remove('animate-in', 'animate-out');
      });
    });
  }

  destroy() {
    window.removeEventListener('scroll', () => this.handleScroll());
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
    console.log('🎠 Initialisation du carousel de cards');
    scrollCardsCarouselInstance = new ScrollCardsCarousel();
  }
}

document.addEventListener('turbo:before-render', () => {
  if (scrollCardsCarouselInstance) {
    console.log('🧹 Nettoyage du carousel avant changement de page');
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
