/**
 * Effet de blur de l'image et animation des textes au scroll pour la section boutique
 */
class SectionBoutiqueBlur {
  constructor() {
    this.containers = document.querySelectorAll('[data-section-boutique]');
    if (this.containers.length === 0) return;
    
    this.init();
  }

  init() {
    // Initialiser l'effet de blur de l'image et animation des textes
    this.handleScrollBound = this.handleScroll.bind(this);
    window.addEventListener('scroll', this.handleScrollBound, { passive: true });
    // Appeler une première fois pour l'état initial
    requestAnimationFrame(() => this.handleScroll());
  }

  handleScroll() {
    this.containers.forEach(container => {
      const image = container.querySelector('[data-section-boutique-image]');
      const textContainer = container.querySelector('.section-boutique-text');
      
      if (!image) return;

      const rect = container.getBoundingClientRect();
      const windowHeight = window.innerHeight;
      const containerCenter = rect.top + (rect.height / 2);
      const viewportCenter = windowHeight / 2;
      
      // Calculer la distance du centre
      const distance = Math.abs(containerCenter - viewportCenter);
      const maxDistance = windowHeight / 3;
      
      // Blur simple : 0 au centre, max 3px aux extrémités
      if (rect.top < windowHeight && rect.bottom > 0) {
        const blur = Math.min(3, (distance / maxDistance) * 3);
        image.style.filter = `blur(${blur}px)`;
      } else {
        image.style.filter = 'blur(0px)';
      }

      // Animation des textes : apparition et disparition progressive au scroll
      if (textContainer) {
        // Calculer la progression du scroll dans la section (0 = début, 1 = fin)
        const sectionHeight = rect.height;
        const rawScrollProgress = (windowHeight - rect.top) / (sectionHeight + windowHeight);
        
        // Phase d'entrée : 0% à 30% du scroll dans la section
        const entryPhaseEnd = 0.3;
        const entryProgress = this.clamp(rawScrollProgress / entryPhaseEnd, 0, 1);
        
        // Phase stable : 30% à 60% du scroll (complètement visible)
        const stablePhaseStart = 0.3;
        const stablePhaseEnd = 0.6;
        
        // Phase de sortie : 60% à 90% du scroll (disparition progressive)
        const exitPhaseStart = 0.6;
        const exitPhaseEnd = 0.9;
        const exitProgress = this.clamp((rawScrollProgress - exitPhaseStart) / (exitPhaseEnd - exitPhaseStart), 0, 1);

        // Animer le titre (effet depuis le haut avec scale)
        const title = textContainer.querySelector('.section-boutique-title');
        if (title) {
          this.animateTitle(title, rawScrollProgress, entryProgress, stablePhaseStart, stablePhaseEnd, exitPhaseStart, exitPhaseEnd, exitProgress);
        }

        // Animer le premier paragraphe (effet depuis la droite)
        const paragraphs = textContainer.querySelectorAll('.section-boutique-paragraph');
        if (paragraphs.length > 0) {
          this.animateParagraph(paragraphs[0], rawScrollProgress, entryProgress, stablePhaseStart, stablePhaseEnd, exitPhaseStart, exitPhaseEnd, exitProgress, 0);
        }

        // Animer le deuxième paragraphe (effet depuis la droite avec délai)
        if (paragraphs.length > 1) {
          this.animateParagraph(paragraphs[1], rawScrollProgress, entryProgress, stablePhaseStart, stablePhaseEnd, exitPhaseStart, exitPhaseEnd, exitProgress, 0.1);
        }
      }
    });
  }

  animateTitle(element, rawScrollProgress, entryProgress, stablePhaseStart, stablePhaseEnd, exitPhaseStart, exitPhaseEnd, exitProgress) {
    if (rawScrollProgress > exitPhaseEnd) {
      // Complètement disparu
      element.style.opacity = '0';
      element.style.transform = 'translateY(-40px) scale(0.9)';
      element.style.visibility = 'hidden';
    } else if (rawScrollProgress > exitPhaseStart) {
      // Phase de sortie : monte et rétrécit
      const opacity = 1 - exitProgress;
      const translateY = -exitProgress * 40;
      const scale = 1 - (exitProgress * 0.1);
      element.style.opacity = opacity;
      element.style.transform = `translateY(${translateY}px) scale(${scale})`;
      element.style.visibility = 'visible';
    } else if (rawScrollProgress > stablePhaseStart) {
      // Phase stable - complètement visible
      element.style.opacity = '1';
      element.style.transform = 'translateY(0) scale(1)';
      element.style.visibility = 'visible';
    } else if (rawScrollProgress > 0) {
      // Phase d'entrée : descend depuis le haut avec scale
      const opacity = entryProgress;
      const translateY = (1 - entryProgress) * -40;
      const scale = 0.9 + (entryProgress * 0.1);
      element.style.opacity = opacity;
      element.style.transform = `translateY(${translateY}px) scale(${scale})`;
      element.style.visibility = 'visible';
    } else {
      // Pas encore visible
      element.style.opacity = '0';
      element.style.transform = 'translateY(-40px) scale(0.9)';
      element.style.visibility = 'hidden';
    }
  }

  animateParagraph(element, rawScrollProgress, entryProgress, stablePhaseStart, stablePhaseEnd, exitPhaseStart, exitPhaseEnd, exitProgress, delay) {
    // Ajuster la progression avec le délai
    const adjustedEntryProgress = this.clamp(entryProgress - delay, 0, 1);
    const adjustedExitProgress = this.clamp(exitProgress - delay, 0, 1);
    
    if (rawScrollProgress > exitPhaseEnd) {
      // Complètement disparu
      element.style.opacity = '0';
      element.style.transform = 'translateX(50px)';
      element.style.visibility = 'hidden';
    } else if (rawScrollProgress > exitPhaseStart) {
      // Phase de sortie : glisse vers la droite
      const opacity = 1 - adjustedExitProgress;
      const translateX = adjustedExitProgress * 50;
      element.style.opacity = opacity;
      element.style.transform = `translateX(${translateX}px)`;
      element.style.visibility = 'visible';
    } else if (rawScrollProgress > stablePhaseStart) {
      // Phase stable - complètement visible
      element.style.opacity = '1';
      element.style.transform = 'translateX(0)';
      element.style.visibility = 'visible';
    } else if (rawScrollProgress > 0 && adjustedEntryProgress > 0) {
      // Phase d'entrée : glisse depuis la droite
      const opacity = adjustedEntryProgress;
      const translateX = (1 - adjustedEntryProgress) * 50;
      element.style.opacity = opacity;
      element.style.transform = `translateX(${translateX}px)`;
      element.style.visibility = 'visible';
    } else {
      // Pas encore visible
      element.style.opacity = '0';
      element.style.transform = 'translateX(50px)';
      element.style.visibility = 'hidden';
    }
  }

  clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
  }

  destroy() {
    // Nettoyer l'event listener
    if (this.handleScrollBound) {
      window.removeEventListener('scroll', this.handleScrollBound);
    }
  }
}

// Instance globale
let sectionBoutiqueBlurInstance = null;

/**
 * Initialiser SectionBoutiqueBlur
 */
function initSectionBoutiqueBlur() {
  // Nettoyer l'ancienne instance
  if (sectionBoutiqueBlurInstance) {
    sectionBoutiqueBlurInstance.destroy();
    sectionBoutiqueBlurInstance = null;
  }

  // Créer la nouvelle instance
  sectionBoutiqueBlurInstance = new SectionBoutiqueBlur();
}

// Nettoyer avant de quitter la page
document.addEventListener('turbo:before-render', () => {
  if (sectionBoutiqueBlurInstance) {
    sectionBoutiqueBlurInstance.destroy();
    sectionBoutiqueBlurInstance = null;
  }
});

// Initialisation avec Turbo
document.addEventListener('turbo:load', initSectionBoutiqueBlur);

// Initialisation sans Turbo (chargement initial)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initSectionBoutiqueBlur);
} else {
  initSectionBoutiqueBlur();
}

export { SectionBoutiqueBlur };
