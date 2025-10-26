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
    
    this.dressCentered = false; // Flag pour le console.log
    this.finalTransform = null; // Transform final à maintenir
    this.fixedStartScroll = null; // Position de scroll où la robe devient fixe
    this.isFixed = false; // Flag pour savoir si la robe est fixe
    this.savedPosition = null; // Position sauvegardée de la robe
    this.fadeStarted = false; // Flag pour le début de la disparition
    this.fadeCompleted = false; // Flag pour la fin de la disparition
    
    this.init();
  }

  init() {
    // Initialiser les styles de la robe
    this.dressColumn.style.opacity = '1';
    this.dressColumn.style.filter = 'blur(0px)';
    
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
    
    // Phase 1 : Déplacer la robe vers le centre (progress < 0.99)
    if (progress < 0.99) {
      // Réinitialiser si on revient en arrière
      if (this.isFixed) {
        this.isFixed = false;
        this.fixedStartScroll = null;
        this.fadeStarted = false;
        this.fadeCompleted = false;
        this.dressColumn.style.position = '';
        this.dressColumn.style.left = '';
        this.dressColumn.style.top = '';
        this.dressColumn.style.width = '';
        this.dressColumn.style.zIndex = '';
        this.dressColumn.style.opacity = '';
        this.dressColumn.style.filter = '';
        this.dressColumn.style.visibility = '';
        this.dressColumn.style.pointerEvents = '';
      }
      
      const moveX = progress * 400; // Déplacement horizontal (400px max)
      const moveY = progress * 300; // Déplacement vertical (200px max)
      const scale = 1 + (progress * 0.8); // Grossir jusqu'à 1.8x
      
      const transform = `translate(${moveX}px, ${moveY}px) scale(${scale})`;
      this.dressColumn.style.transform = transform;
      this.dressColumn.style.transition = 'none';
      
      // Sauvegarder le transform final
      this.finalTransform = transform;
      
      // Réinitialiser le flag
      if (this.dressCentered) {
        this.dressCentered = false;
      }
    } 
    // Phase 2 : Fixer la robe au centre de l'écran pendant 200px de scroll
    else {
      if (!this.isFixed) {
        // Première fois qu'on atteint le centre : fixer la robe
        this.fixedStartScroll = scrollPosition;
        
        // Capturer la position actuelle AVEC le transform appliqué
        const rect = this.dressColumn.getBoundingClientRect();
        
        // Calculer le centre de la robe actuellement affichée
        const centerX = rect.left + rect.width / 2;
        const centerY = rect.top + rect.height / 2;
        
        // La largeur/hauteur scalée est déjà dans rect
        const scaledWidth = rect.width;
        const scaledHeight = rect.height;
        
        // Pour que le scale(1.8) avec transform-origin center center fonctionne,
        // on doit positionner le coin supérieur gauche de l'élément non-scalé
        // La taille non-scalée est : scaledWidth / 1.8
        const baseWidth = scaledWidth / 1.8;
        const baseHeight = scaledHeight / 1.8;
        
        // Position du coin supérieur gauche pour que le centre reste au bon endroit après scale
        const left = centerX - baseWidth / 2;
        const top = centerY - baseHeight / 2;
        
        // Passer en position fixed
        this.dressColumn.style.position = 'fixed';
        this.dressColumn.style.left = `${left}px`;
        this.dressColumn.style.top = `${top}px`;
        this.dressColumn.style.width = `${baseWidth}px`;
        this.dressColumn.style.zIndex = '1000';
        
        // Appliquer seulement le scale avec transform-origin center
        this.dressColumn.style.transform = 'scale(1.8)';
        this.dressColumn.style.transformOrigin = 'center center';
        
        this.isFixed = true;
        
        // Console.log une seule fois
        if (!this.dressCentered) {
          this.dressCentered = true;
          console.log('🎯 La robe est fixée au centre de l\'écran pendant 200px de scroll!');
        }
      }
      
      // Phase 3 : Disparition en nuage après 200px de scroll
      const scrolledSinceFixed = scrollPosition - this.fixedStartScroll;
      
      if (scrolledSinceFixed <= 200) {
        // Phase de maintien : la robe reste fixe et visible
        this.dressColumn.style.opacity = '1';
        this.dressColumn.style.filter = 'blur(0px)';
        
        // Réinitialiser les flags si on revient en arrière
        if (this.fadeStarted) {
          this.fadeStarted = false;
          this.fadeCompleted = false;
        }
      } else {
        // Phase de disparition : effet de nuage
        const fadeDistance = 200; // 200px pour disparaître complètement
        const fadeProgress = Math.min((scrolledSinceFixed - 200) / fadeDistance, 1);
        
        // Opacité décroissante
        const opacity = 1 - fadeProgress;
        
        // Flou croissant (effet de brouillard/nuage)
        const blur = fadeProgress * 30; // Jusqu'à 30px de flou
        
        // Légère expansion pour simuler la dispersion
        const expansionScale = 1.8 + (fadeProgress * 0.3); // De 1.8 à 2.1
        
        this.dressColumn.style.opacity = opacity;
        this.dressColumn.style.filter = `blur(${blur}px)`;
        this.dressColumn.style.transform = `scale(${expansionScale})`;
        
        // Console.log une seule fois quand la disparition commence
        if (fadeProgress > 0 && fadeProgress < 0.01 && !this.fadeStarted) {
          this.fadeStarted = true;
          console.log('💨 La robe commence à disparaître dans un nuage...');
        }
        
        // Masquer complètement quand invisible
        if (fadeProgress >= 0.99) {
          this.dressColumn.style.visibility = 'hidden';
          this.dressColumn.style.pointerEvents = 'none';
          
          if (!this.fadeCompleted) {
            this.fadeCompleted = true;
            console.log('✨ La robe a complètement disparu!');
          }
        } else {
          this.dressColumn.style.visibility = 'visible';
        }
      }
    }
    
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

