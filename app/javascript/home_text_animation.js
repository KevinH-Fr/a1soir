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
 * Gestion du scroll fluide vers le bas et disparition de la flèche
 */
class ScrollIndicatorHandler {
  constructor() {
    this.scrollIndicator = document.querySelector('.scroll-indicator');
    if (!this.scrollIndicator) return;

    this.init();
  }

  init() {
    // Scroll smooth au clic - descendre d'une hauteur d'écran à chaque clic
    this.scrollIndicator.addEventListener('click', () => {
      const currentScroll = window.pageYOffset;
      const windowHeight = window.innerHeight;
      const documentHeight = document.documentElement.scrollHeight;
      
      // Calculer la nouvelle position (une hauteur d'écran plus bas)
      const targetScroll = currentScroll + windowHeight;
      
      // S'assurer qu'on ne dépasse pas le bas de la page
      const maxScroll = documentHeight - windowHeight;
      const finalScroll = Math.min(targetScroll, maxScroll);
      
      window.scrollTo({
        top: finalScroll,
        behavior: 'smooth'
      });
    });

    // Faire disparaître la flèche quand on est proche du bas
    window.addEventListener('scroll', () => this.handleScroll());
    this.handleScroll();
  }

  handleScroll() {
    const scrollPosition = window.pageYOffset;
    const windowHeight = window.innerHeight;
    const documentHeight = document.documentElement.scrollHeight;
    const distanceFromBottom = documentHeight - (scrollPosition + windowHeight);
    
    // Disparaître quand on est à moins de 200px du bas
    const hideThreshold = 200;
    
    if (distanceFromBottom < hideThreshold) {
      const fadeProgress = distanceFromBottom / hideThreshold;
      this.scrollIndicator.style.opacity = Math.max(0, fadeProgress).toString();
      if (fadeProgress <= 0) {
        this.scrollIndicator.style.visibility = 'hidden';
      }
    } else {
      this.scrollIndicator.style.opacity = '1';
      this.scrollIndicator.style.visibility = 'visible';
    }
  }
}

/**
 * Effet de disparition des textes au scroll
 */
class TextFadeOnScroll {
  constructor() {
    this.textContent = document.querySelector('.text-content');
    this.heroSection = document.querySelector('.home-hero');
    
    if (!this.textContent || !this.heroSection) return;
    
    this.init();
  }

  init() {
    // Mettre les enfants textes en position fixed dès l'initialisation
    // Exclure le scroll-indicator qui doit rester à 50px du bas
    const children = this.textContent.children;
    for (let i = 0; i < children.length; i++) {
      const child = children[i];
      // Ignorer le scroll-indicator qui a sa propre position
      if (child.classList.contains('scroll-indicator')) continue;
      
      const rect = child.getBoundingClientRect();
      child.style.position = 'fixed';
      child.style.top = `${rect.top}px`;
      child.style.left = `${rect.left}px`;
      child.style.width = `${rect.width}px`;
      child.style.zIndex = '10';
    }
    
    window.addEventListener('scroll', () => this.handleScroll());
    setTimeout(() => this.handleScroll(), 500);
  }

  handleScroll() {
    const scrollPosition = window.pageYOffset;
    const heroHeight = this.heroSection.offsetHeight;
    
    // Base de progression pour le scroll
    const baseProgress = scrollPosition / (heroHeight * 0.3);
    
    // Décalages pour la disparition séquentielle (en pourcentage de la progression totale)
    const titleStart = 0;           // Le titre commence à disparaître dès le début
    const subtitleStart = 0.15;     // Le sous-titre commence après 15% de progression
    const animatedTextStart = 0.3;  // Le texte animé commence après 30% de progression
    
    // Durée de disparition pour chaque élément (en pourcentage de la progression totale)
    const fadeDuration = 0.4; // 40% de la progression totale pour disparaître complètement
    
    // Calculer les progressions décalées pour chaque élément
    const titleProgress = Math.max(0, Math.min((baseProgress - titleStart) / fadeDuration, 1));
    const subtitleProgress = Math.max(0, Math.min((baseProgress - subtitleStart) / fadeDuration, 1));
    const animatedTextProgress = Math.max(0, Math.min((baseProgress - animatedTextStart) / fadeDuration, 1));
    
    // S'assurer que le conteneur n'a pas de transform
    this.textContent.style.transform = 'none';
    
    // Appliquer l'effet de fumée à tous les enfants
    const children = this.textContent.children;
    
    for (let i = 0; i < children.length; i++) {
      const child = children[i];
      
      // Ignorer le scroll-indicator qui doit rester visible et à sa position
      if (child.classList.contains('scroll-indicator')) continue;
      
      // Le titre disparaît en premier
      if (child.classList.contains('hero-gradient-text')) {
        const opacity = 1 - titleProgress;
        child.style.opacity = opacity;
        child.style.transform = 'none';
        child.style.filter = 'none';
        child.style.visibility = opacity <= 0.01 ? 'hidden' : 'visible';
      }
      // Le sous-titre disparaît en deuxième
      else if (child.classList.contains('hero-gradient-subtitle')) {
        const opacity = 1 - subtitleProgress;
        const blur = subtitleProgress * 20;
        const scale = 1 + (subtitleProgress * 0.2);
        
        child.style.opacity = opacity;
        child.style.filter = `blur(${blur}px)`;
        child.style.transform = `scale(${scale})`;
        child.style.transition = 'opacity 0.1s ease-out, filter 0.1s ease-out, transform 0.1s ease-out';
        child.style.visibility = opacity <= 0.01 ? 'hidden' : 'visible';
        child.style.pointerEvents = opacity <= 0.01 ? 'none' : 'auto';
      }
      // Le texte animé disparaît en dernier
      else if (child.classList.contains('animated-text-container')) {
        const opacity = 1 - animatedTextProgress;
        const blur = animatedTextProgress * 20;
        const scale = 1 + (animatedTextProgress * 0.2);
        
        child.style.opacity = opacity;
        child.style.filter = `blur(${blur}px)`;
        child.style.transform = `scale(${scale})`;
        child.style.transition = 'opacity 0.1s ease-out, filter 0.1s ease-out, transform 0.1s ease-out';
        child.style.visibility = opacity <= 0.01 ? 'hidden' : 'visible';
        child.style.pointerEvents = opacity <= 0.01 ? 'none' : 'auto';
      }
    }
  }
}

// Instances globales
let textAnimationInstance = null;
let scrollIndicatorInstance = null;
let textFadeInstance = null;

/**
 * Nettoyer toutes les instances
 */
function cleanupHomeAnimations() {
  if (textAnimationInstance) {
    textAnimationInstance.destroy();
    textAnimationInstance = null;
  }
  scrollIndicatorInstance = null;
  textFadeInstance = null;
}

/**
 * Initialiser les animations de la page d'accueil
 */
function initHomeAnimations() {
  if (!document.getElementById('changing-text')) return;
  
  cleanupHomeAnimations();
  textAnimationInstance = new HomeTextAnimation();
  scrollIndicatorInstance = new ScrollIndicatorHandler();
  textFadeInstance = new TextFadeOnScroll();
}

// Nettoyer avant de quitter la page
document.addEventListener('turbo:before-render', cleanupHomeAnimations);

// Initialisation avec Turbo
document.addEventListener('turbo:load', initHomeAnimations);

// Initialisation sans Turbo (chargement initial)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initHomeAnimations);
} else {
  initHomeAnimations();
}

export { HomeTextAnimation, ScrollIndicatorHandler, TextFadeOnScroll };

