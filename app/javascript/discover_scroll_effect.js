/**
 * Effets de scroll pour la section "Découvrez notre univers"
 * Animations progressives basées sur la position du scroll
 */
class DiscoverScrollEffect {
  constructor() {
    this.section = document.querySelector('[data-discover]');
    if (!this.section) return;
    
    this.items = Array.from(this.section.querySelectorAll('[data-discover-item]'));
    this.handleScrollBound = this.handleScroll.bind(this);
    this.init();
  }

  init() {
    // Écouter le scroll
    window.addEventListener('scroll', this.handleScrollBound, { passive: true });
    // Appliquer l'effet initial
    requestAnimationFrame(() => this.handleScroll());
  }

  handleScroll() {
    if (!this.section) return;

    const rect = this.section.getBoundingClientRect();
    const windowHeight = window.innerHeight;
    const sectionHeight = rect.height;

    // Calculer la position de scroll dans la section (0 = début, 1 = fin)
    const scrollProgress = this.clamp((windowHeight - rect.top) / (sectionHeight + windowHeight), 0, 1);

    // Phase d'entrée : 0% à 30% du scroll
    const entryPhaseEnd = 0.3;
    const entryProgress = this.clamp(scrollProgress / entryPhaseEnd, 0, 1);

    // Phase stable : 30% à 60% du scroll (complètement visible)
    const stablePhaseStart = 0.3;
    const stablePhaseEnd = 0.6;

    // Phase de sortie : 60% à 90% du scroll
    const exitPhaseStart = 0.6;
    const exitPhaseEnd = 0.9;
    const exitProgress = this.clamp((scrollProgress - exitPhaseStart) / (exitPhaseEnd - exitPhaseStart), 0, 1);

    // Appliquer les transformations à chaque item
    this.items.forEach((item, index) => {
      // Délai pour effet séquentiel
      const delay = index * 0.15;
      const adjustedEntryProgress = this.clamp(entryProgress - delay, 0, 1);
      const adjustedExitProgress = this.clamp(exitProgress - delay, 0, 1);

      if (scrollProgress > exitPhaseStart) {
        // Phase de sortie (fumée)
        this.applyExitEffect(item, adjustedExitProgress);
      } else if (scrollProgress > 0) {
        // Phase d'entrée et phase stable
        if (adjustedEntryProgress >= 1) {
          // Phase stable - complètement visible
          item.style.opacity = '1';
          item.style.transform = 'translateY(0) scale(1)';
          item.style.filter = 'blur(0px)';
        } else {
          // Phase d'entrée en cours
          this.applyEntryEffect(item, adjustedEntryProgress);
        }
      } else {
        // Pas encore visible
        this.resetItem(item);
      }
    });
  }

  applyEntryEffect(item, progress) {
    // Interpolation pour l'entrée
    const opacity = progress;
    const translateY = (1 - progress) * 40; // De 40px à 0
    
    item.style.opacity = opacity;
    item.style.transform = `translateY(${translateY}px)`;
    item.style.filter = 'blur(0px)';
  }

  applyExitEffect(item, progress) {
    // Interpolation pour la sortie (fumée)
    const opacity = 1 - progress;
    const translateY = -progress * 60; // Monte jusqu'à -60px
    const scale = 1 + (progress * 0.3); // Agrandit jusqu'à 1.3x
    const blur = progress * 20; // Flou jusqu'à 20px
    
    item.style.opacity = opacity;
    item.style.transform = `translateY(${translateY}px) scale(${scale})`;
    item.style.filter = `blur(${blur}px)`;
  }

  resetItem(item) {
    item.style.opacity = '0';
    item.style.transform = 'translateY(40px)';
    item.style.filter = 'blur(0px)';
  }

  clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
  }

  destroy() {
    if (this.handleScrollBound) {
      window.removeEventListener('scroll', this.handleScrollBound);
    }
    // Réinitialiser les items
    this.items.forEach(item => {
      item.style.opacity = '';
      item.style.transform = '';
      item.style.filter = '';
    });
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
  const section = document.querySelector('[data-discover]');
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

