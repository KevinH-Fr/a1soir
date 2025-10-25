/**
 * Animation du texte qui change sur la page d'accueil
 * Animation d'entrée : glisse depuis la droite
 * Animation de sortie : disparaît comme de la fumée
 */
class HomeTextAnimation {
  constructor() {
    this.changingText = document.getElementById('changing-text');
    if (!this.changingText) return;

    this.texts = [
      'Tenues de soirée',
      'Robes de mariées',
      'Costumes',
      'Smokings',
      'Tenues d\'époque',
      'Accessoires'
    ];
    this.currentIndex = 0;
    this.intervalId = null;

    this.init();
  }

  init() {
    // Commencer avec un texte vide
    this.changingText.textContent = '';
    
    // Faire apparaître le premier texte après un court délai
    setTimeout(() => {
      this.showNextText();
    }, 500);
    
    // Démarrer le cycle de changement de texte
    this.start();
  }

  showNextText() {
    // Afficher le texte actuel
    this.changingText.textContent = this.texts[this.currentIndex];
    
    // Lancer l'animation d'entrée
    this.changingText.classList.remove('fade-out');
    this.changingText.classList.add('slide-in');
  }

  changeText() {
    // Animation de disparition (fumée)
    this.changingText.classList.remove('slide-in');
    this.changingText.classList.add('fade-out');
    
    // Attendre la fin de l'animation de disparition
    setTimeout(() => {
      // Passer au texte suivant
      this.currentIndex = (this.currentIndex + 1) % this.texts.length;
      
      // Petit délai pour forcer la réinitialisation de l'animation
      setTimeout(() => {
        this.showNextText();
      }, 50);
    }, 800); // Durée de l'animation fade-out
  }

  start() {
    // Changer le texte toutes les 3.5 secondes
    this.intervalId = setInterval(() => this.changeText(), 3500);
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  destroy() {
    this.stop();
  }
}

/**
 * Gestion du scroll fluide vers le bas
 */
class ScrollIndicatorHandler {
  constructor() {
    this.scrollIndicator = document.querySelector('.scroll-indicator');
    if (!this.scrollIndicator) return;

    this.init();
  }

  init() {
    this.scrollIndicator.addEventListener('click', () => {
      window.scrollTo({
        top: window.innerHeight,
        behavior: 'smooth'
      });
    });
  }
}

/**
 * Effet de disparition des textes et déplacement de la robe au scroll
 */
class TextFadeOnScroll {
  constructor() {
    this.textContent = document.querySelector('.text-content');
    this.dressColumn = document.querySelector('.dress-column');
    this.heroSection = document.querySelector('.home-hero');
    
    if (!this.textContent || !this.dressColumn || !this.heroSection) return;
    
    this.init();
  }

  init() {
    window.addEventListener('scroll', () => this.handleScroll());
    
    // Initialiser après un court délai pour s'assurer que le listener de la robe est attaché
    setTimeout(() => {
      this.handleScroll();
    }, 500);
  }

  handleScroll() {
    const scrollPosition = window.pageYOffset;
    const heroHeight = this.heroSection.offsetHeight;
    
    // Calculer le facteur de progression (0 = en haut, 1 = en bas du hero)
    // Réduit de 0.5 à 0.3 pour une disparition plus rapide
    const progress = Math.min(scrollPosition / (heroHeight * 0.3), 1);
    
    // Faire disparaître les textes progressivement
    this.textContent.style.opacity = 1 - progress;
    
    // Masquer complètement quand invisible pour éviter l'interaction
    if (progress >= 0.99) {
      this.textContent.style.visibility = 'hidden';
      this.textContent.style.pointerEvents = 'none';
    } else {
      this.textContent.style.visibility = 'visible';
      this.textContent.style.pointerEvents = 'auto';
    }
    
    // Déplacer la robe vers la droite et le bas
    const moveX = progress * 400; // Déplacement horizontal (400px max)
    const moveY = progress * 300; // Déplacement vertical (200px max)
    
    // Grossir la robe proportionnellement
    const scale = 1 + (progress * 0.8); // Grossir jusqu'à 1.8x
    
    this.dressColumn.style.transform = `translate(${moveX}px, ${moveY}px) scale(${scale})`;
    this.dressColumn.style.transition = 'none';
    
    // Accélérer la rotation de la robe
    // Envoyer un événement personnalisé pour modifier la vitesse de rotation
    const rotationSpeedMultiplier = 1 + (progress * 4); // Jusqu'à 5x plus rapide
    window.dispatchEvent(new CustomEvent('dress-rotation-speed', { 
      detail: { multiplier: rotationSpeedMultiplier } 
    }));
  }
}

// Instances globales
let textAnimationInstance = null;
let scrollIndicatorInstance = null;
let textFadeInstance = null;

/**
 * Initialiser les animations de la page d'accueil
 */
function initHomeAnimations() {
  // Nettoyer les anciennes instances si elles existent
  if (textAnimationInstance) {
    textAnimationInstance.destroy();
  }

  // Créer les nouvelles instances
  textAnimationInstance = new HomeTextAnimation();
  scrollIndicatorInstance = new ScrollIndicatorHandler();
  textFadeInstance = new TextFadeOnScroll();
}

// Initialisation avec Turbo
document.addEventListener('turbo:load', initHomeAnimations);

// Initialisation sans Turbo (chargement initial)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initHomeAnimations);
} else {
  initHomeAnimations();
}

export { HomeTextAnimation, ScrollIndicatorHandler, TextFadeOnScroll };

