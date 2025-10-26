/**
 * Effets de scroll pour la section "Découvrez notre univers"
 * Effet de disparition en fumée
 */
class DiscoverScrollEffect {
  constructor() {
    this.section = document.querySelector('.discover-section');
    this.content = document.querySelector('.discover-content');
    this.titleWrapper = document.querySelector('.discover-title-wrapper');
    this.description = document.querySelector('.discover-description');
    this.icons = document.querySelector('.discover-icons');
    
    if (!this.section || !this.content) return;
    
    this.hasAppeared = false;
    this.smokeStarted = false;
    this.smokeEnded = false;
    this.handleScrollBound = this.handleScroll.bind(this);
    this.init();
  }

  init() {
    // Écouter le scroll pour l'effet de fumée
    window.addEventListener('scroll', this.handleScrollBound, { passive: true });
    
    // Vérifier la position initiale immédiatement et après un délai
    requestAnimationFrame(() => {
      this.handleScroll();
      setTimeout(() => this.handleScroll(), 100);
    });
  }

  handleScroll() {
    if (!this.section || !this.content) return;

    const sectionRect = this.section.getBoundingClientRect();
    const windowHeight = window.innerHeight;

    // Détecter si la section est visible dans le viewport
    const isInViewport = sectionRect.top < windowHeight * 0.8 && sectionRect.bottom > 0;

    // Faire apparaître le contenu quand la section entre dans le viewport
    if (isInViewport && !this.hasAppeared) {
      this.showContent();
      this.hasAppeared = true;
    }

    // Calculer la progression du scroll dans la section
    let progress = 0;
    
    // Si la section est dans le viewport
    if (sectionRect.bottom > 0 && sectionRect.top < windowHeight) {
      // L'effet de fumée commence quand la section atteint le haut de l'écran
      if (sectionRect.top <= 0) {
        // On est dans la phase de disparition
        const scrolled = Math.abs(sectionRect.top);
        const scrollableHeight = sectionRect.height - windowHeight;
        progress = Math.max(0, Math.min(1, scrolled / scrollableHeight));
      }
    } else if (sectionRect.top >= windowHeight) {
      // Section pas encore visible, réinitialiser
      if (this.hasAppeared) {
        this.hideContent();
        this.hasAppeared = false;
      }
      progress = 0;
    } else {
      // Section déjà dépassée, masquer complètement
      progress = 1;
    }

    // Appliquer l'effet de fumée seulement si le contenu est apparu
    if (this.hasAppeared) {
      this.applySmokeEffect(progress);
    }
  }

  showContent() {
    if (!this.content) return;
    this.content.style.opacity = '1';
    this.content.style.visibility = 'visible';
  }

  hideContent() {
    if (!this.content) return;
    this.content.style.opacity = '0';
    this.content.style.visibility = 'hidden';
    // Réinitialiser les effets de fumée
    this.resetElements();
  }

  applySmokeEffect(progress) {
    if (!this.content) return;

    // Si progress > 0, on désactive l'animation d'entrée pour permettre l'effet de fumée
    if (progress > 0.05) {
      this.content.style.animation = 'none';
    }

    // Disparition en cascade : chaque élément disparaît l'un après l'autre
    // Titre : 0% - 33%
    // Description : 33% - 66%
    // Icônes : 66% - 100%
    
    // Effet de fumée sur le titre (première phase)
    if (this.titleWrapper) {
      const titleProgress = Math.max(0, Math.min(1, progress / 0.33));
      this.applySmokeToElement(this.titleWrapper, titleProgress, 'titre');
    }
    
    // Effet de fumée sur la description (deuxième phase)
    if (this.description) {
      const descProgress = Math.max(0, Math.min(1, (progress - 0.33) / 0.33));
      this.applySmokeToElement(this.description, descProgress, 'description');
    }
    
    // Effet de fumée sur les icônes (troisième phase)
    if (this.icons) {
      const iconsProgress = Math.max(0, Math.min(1, (progress - 0.66) / 0.34));
      this.applySmokeToElement(this.icons, iconsProgress, 'icônes');
    }

    // Masquer complètement le contenu à la fin
    if (progress >= 0.95) {
      this.content.style.visibility = 'hidden';
      this.content.style.pointerEvents = 'none';
    } else {
      this.content.style.visibility = 'visible';
      this.content.style.pointerEvents = 'none';
    }
    
    // Réinitialiser les flags et styles si on revient en arrière
    if (progress === 0) {
      this.resetElements();
    }
  }

  applySmokeToElement(element, progress, name) {
    if (!element) return;

    // Opacité décroissante
    const opacity = 1 - progress;
    
    // Flou croissant
    const blur = progress * 25; // Jusqu'à 25px de flou
    
    // Scale croissant (expansion)
    const scale = 1 + (progress * 0.4); // Jusqu'à 1.4x
    
    // Translation vers le haut (effet de montée de fumée)
    const translateY = -progress * 30; // Monte de 30px

    element.style.opacity = Math.max(0, opacity);
    element.style.filter = `blur(${blur}px)`;
    element.style.transform = `translateY(${translateY}px) scale(${scale})`;
  }

  resetElements() {
    // Réinitialiser tous les éléments
    [this.titleWrapper, this.description, this.icons].forEach(element => {
      if (element) {
        element.style.opacity = '';
        element.style.filter = '';
        element.style.transform = '';
      }
    });
    
    this.smokeStarted = false;
    this.smokeEnded = false;
  }

  destroy() {
    if (this.handleScrollBound) {
      window.removeEventListener('scroll', this.handleScrollBound);
    }
  }
}

// Instance globale
let discoverScrollEffectInstance = null;

/**
 * Initialiser les effets de scroll
 */
function initDiscoverScrollEffect() {
  // Nettoyer l'ancienne instance
  if (discoverScrollEffectInstance) {
    discoverScrollEffectInstance.destroy();
    discoverScrollEffectInstance = null;
  }

  // Créer la nouvelle instance seulement si la section existe sur la page
  const section = document.querySelector('.discover-section');
  if (section) {
    discoverScrollEffectInstance = new DiscoverScrollEffect();
  }
}

// Nettoyer avant de quitter la page
document.addEventListener('turbo:before-render', () => {
  if (discoverScrollEffectInstance) {
    discoverScrollEffectInstance.destroy();
    discoverScrollEffectInstance = null;
  }
});

// Initialisation avec Turbo
document.addEventListener('turbo:load', initDiscoverScrollEffect);

// Initialisation sans Turbo (chargement initial)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initDiscoverScrollEffect);
} else {
  initDiscoverScrollEffect();
}

export { DiscoverScrollEffect };

