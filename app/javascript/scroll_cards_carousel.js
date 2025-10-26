/**
 * Carousel de cards contrôlé par le scroll
 * Les cards arrivent une par une depuis la droite et disparaissent
 */
class ScrollCardsCarousel {
  constructor() {
    this.carousel = document.querySelector('.scroll-cards-carousel');
    this.container = document.querySelector('.scroll-cards-container');
    this.cards = document.querySelectorAll('.scroll-card');
    
    if (!this.carousel || !this.container || this.cards.length === 0) return;
    
    this.currentCardIndex = -1; // -1 = aucune card visible
    this.isInView = false;
    
    this.init();
  }

  init() {
    // Cacher le container au départ
    this.container.style.opacity = '0';
    this.container.style.visibility = 'hidden';
    this.container.style.transition = 'opacity 0.3s ease, visibility 0.3s ease';
    
    // Initialiser toutes les cards hors écran (à droite)
    this.cards.forEach(card => {
      card.style.opacity = '0';
      card.style.transform = 'translate(-50%, -50%) translateX(200px)';
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
      // Si on est avant ou après la zone du carousel
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
    // 0 = début du carousel, 1 = fin du carousel
    const scrolled = Math.abs(carouselRect.top);
    const scrollableHeight = carouselRect.height - windowHeight;
    const progress = Math.max(0, Math.min(1, scrolled / scrollableHeight));
    
    // Déterminer quelle card devrait être visible
    const numCards = this.cards.length;
    const segmentSize = 1 / numCards;
    
    // Zone de fade out : les 10% finaux du carousel
    const fadeOutStart = 0.85; // Commence à disparaître à 85% du scroll
    
    if (progress >= fadeOutStart) {
      // Calculer l'opacité de disparition
      const fadeProgress = (progress - fadeOutStart) / (1 - fadeOutStart);
      const opacity = 1 - fadeProgress;
      
      this.container.style.opacity = Math.max(0, opacity).toString();
      
      // Log pour debug
      if (fadeProgress > 0 && fadeProgress < 0.1) {
        console.log('🌅 Le carousel commence à disparaître...');
      }
      
      if (progress >= 0.98) {
        this.container.style.visibility = 'hidden';
        console.log('✨ Le carousel a complètement disparu');
      }
    } else {
      // Réinitialiser l'opacité si on revient en arrière
      this.container.style.opacity = '1';
      this.container.style.visibility = 'visible';
    }
    
    // Calculer l'index de la card à afficher
    let targetCardIndex = -1;
    
    for (let i = 0; i < numCards; i++) {
      const segmentStart = i * segmentSize;
      const segmentEnd = (i + 1) * segmentSize;
      
      if (progress >= segmentStart && progress < segmentEnd) {
        targetCardIndex = i;
        break;
      }
    }
    
    // Si on est à la toute fin, afficher la dernière card
    if (progress >= 1 - segmentSize * 0.1 && progress < fadeOutStart) {
      targetCardIndex = numCards - 1;
    }
    
    // Si la card cible a changé, faire la transition
    if (targetCardIndex !== this.currentCardIndex && targetCardIndex >= 0) {
      this.transitionToCard(targetCardIndex);
    }
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

  transitionToCard(newIndex) {
    const oldIndex = this.currentCardIndex;
    
    // Faire disparaître l'ancienne card avec animations internes
    if (oldIndex >= 0 && oldIndex < this.cards.length) {
      const oldCard = this.cards[oldIndex];
      
      // Animer la sortie des éléments internes d'abord
      this.animateCardExit(oldCard);
      
      // Puis faire sortir la card complète
      setTimeout(() => {
        oldCard.style.transition = 'all 0.6s cubic-bezier(0.4, 0.0, 0.2, 1)';
        oldCard.style.opacity = '0';
        oldCard.style.transform = 'translate(-50%, -50%) translateX(-200px)';
      }, 100);
      
      console.log(`📤 Card ${oldIndex + 1} disparaît vers la gauche`);
    }
    
    // Afficher la nouvelle card avec animations internes
    if (newIndex >= 0 && newIndex < this.cards.length) {
      const newCard = this.cards[newIndex];
      
      // Réinitialiser la position de départ (à droite)
      newCard.style.transition = 'none';
      newCard.style.opacity = '0';
      newCard.style.transform = 'translate(-50%, -50%) translateX(200px)';
      
      // Petit délai pour laisser le temps à l'ancienne card de partir
      setTimeout(() => {
        newCard.style.transition = 'all 0.8s cubic-bezier(0.4, 0.0, 0.2, 1)';
        newCard.style.opacity = '1';
        newCard.style.transform = 'translate(-50%, -50%) translateX(0)';
        
        // Animer l'entrée des éléments internes après que la card soit visible
        setTimeout(() => {
          this.animateCardEnter(newCard);
        }, 200);
        
        console.log(`📥 Card ${newIndex + 1}/${this.cards.length} arrive au centre`);
      }, oldIndex >= 0 ? 200 : 0);
    }
    
    this.currentCardIndex = newIndex;
  }

  animateCardEnter(card) {
    const icon = card.querySelector('.nav-card-icon');
    const title = card.querySelector('.nav-card-title');
    const description = card.querySelector('.nav-card-description');
    const arrow = card.querySelector('.nav-card-arrow');
    
    // Retirer les classes de sortie si présentes
    [icon, title, description, arrow].forEach(el => {
      if (el) el.classList.remove('animate-out');
    });
    
    // Ajouter les classes d'entrée séquentiellement
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
    
    // Retirer les classes d'entrée
    [icon, title, description, arrow].forEach(el => {
      if (el) el.classList.remove('animate-in');
    });
    
    // Ajouter les classes de sortie séquentiellement
    if (arrow) arrow.classList.add('animate-out');
    if (description) description.classList.add('animate-out');
    if (title) title.classList.add('animate-out');
    if (icon) icon.classList.add('animate-out');
  }

  resetCarousel() {
    this.currentCardIndex = -1;
    
    // Réinitialiser toutes les cards
    this.cards.forEach(card => {
      card.style.transition = 'all 0.3s ease';
      card.style.opacity = '0';
      card.style.transform = 'translate(-50%, -50%) translateX(200px)';
      
      // Réinitialiser les animations des éléments internes
      const elements = card.querySelectorAll('.nav-card-icon, .nav-card-title, .nav-card-description, .nav-card-arrow');
      elements.forEach(el => {
        el.classList.remove('animate-in', 'animate-out');
      });
    });
    
    console.log('🔄 Carousel réinitialisé');
  }

  destroy() {
    window.removeEventListener('scroll', () => this.handleScroll());
  }
}

// Instance globale
let scrollCardsCarouselInstance = null;

/**
 * Initialiser le carousel
 */
function initScrollCardsCarousel() {
  // Nettoyer l'ancienne instance
  if (scrollCardsCarouselInstance) {
    scrollCardsCarouselInstance.destroy();
    scrollCardsCarouselInstance = null;
  }

  // Créer la nouvelle instance seulement si le carousel existe sur la page
  const carousel = document.querySelector('.scroll-cards-carousel');
  if (carousel) {
    console.log('🎠 Initialisation du carousel de cards');
    scrollCardsCarouselInstance = new ScrollCardsCarousel();
  }
}

// Nettoyer avant de quitter la page
document.addEventListener('turbo:before-render', () => {
  if (scrollCardsCarouselInstance) {
    console.log('🧹 Nettoyage du carousel avant changement de page');
    scrollCardsCarouselInstance.destroy();
    scrollCardsCarouselInstance = null;
  }
});

// Initialisation avec Turbo
document.addEventListener('turbo:load', initScrollCardsCarousel);

// Initialisation sans Turbo (chargement initial)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initScrollCardsCarousel);
} else {
  initScrollCardsCarousel();
}

export { ScrollCardsCarousel };

