/**
 * Animation d'apparition/disparition séquentielle pour les icônes
 * Entrée: gauche -> centre -> droite (au scroll vers le bas)
 * Sortie: droite -> centre -> gauche (au scroll vers le haut)
 */
class DiscoverIconsAnimation {
  constructor() {
    this.iconsContainer = document.querySelector('.discover-icons');
    if (!this.iconsContainer) return;
    
    this.icons = Array.from(this.iconsContainer.querySelectorAll('.icon-item'));
    if (this.icons.length === 0) return;
    
    this.section = this.iconsContainer.closest('[data-discover]');
    if (!this.section) return;
    
    this.handleScrollBound = this.handleScroll.bind(this);
    
    this.init();
  }

  init() {
    // Initialiser tous les icônes en invisible
    this.icons.forEach(icon => {
      icon.style.opacity = '0';
      icon.style.transform = 'translateY(20px) scale(0.8)';
      icon.style.transition = 'all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)';
    });
    
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

    // Phase d'entrée : 0% à 60% du scroll (icônes apparaissent)
    const entryPhaseEnd = 0.6;
    const entryProgress = this.clamp(scrollProgress / entryPhaseEnd, 0, 1);

    // Phase de sortie : 70% à 100% du scroll (icônes disparaissent)
    const exitPhaseStart = 0.7;
    const exitPhaseEnd = 0.95; // Terminer à 95% pour s'assurer que tout disparaît
    const exitProgress = this.clamp((scrollProgress - exitPhaseStart) / (exitPhaseEnd - exitPhaseStart), 0, 1);

    // Appliquer les animations aux icônes
    this.icons.forEach((icon, index) => {
      if (scrollProgress > exitPhaseStart) {
        // Phase de sortie: de droite à gauche
        const exitIndex = this.icons.length - 1 - index;
        const exitDelay = exitIndex * 0.1; // Délai plus court pour disparition plus rapide
        const adjustedExitProgress = this.clamp(exitProgress - exitDelay, 0, 1);
        
        // S'assurer que l'opacité devient bien 0 à la fin ou si on dépasse la phase de sortie
        if (adjustedExitProgress >= 1 || scrollProgress > exitPhaseEnd) {
          icon.style.opacity = '0';
          icon.style.transform = 'translateY(20px) scale(0.8)';
        } else {
          this.applyIconEffect(icon, 'exit', adjustedExitProgress);
        }
      } else if (scrollProgress > 0) {
        // Phase d'entrée: de gauche à droite
        const entryDelay = index * 0.25; // Délai plus long entre chaque icône
        const adjustedEntryProgress = this.clamp(entryProgress - entryDelay, 0, 1);
        this.applyIconEffect(icon, 'enter', adjustedEntryProgress);
      } else {
        // Pas encore visible
        this.resetIcon(icon);
      }
    });
  }

  applyIconEffect(icon, phase, progress) {
    if (phase === 'enter') {
      // Interpolation pour l'entrée
      const opacity = progress;
      const translateY = (1 - progress) * 20;
      const scale = 0.8 + (progress * 0.2); // De 0.8 à 1
      
      icon.style.opacity = opacity;
      icon.style.transform = `translateY(${translateY}px) scale(${scale})`;
    } else if (phase === 'exit') {
      // Interpolation pour la sortie
      const opacity = 1 - progress;
      const translateY = progress * 20;
      const scale = 1 - (progress * 0.2); // De 1 à 0.8
      
      icon.style.opacity = opacity;
      icon.style.transform = `translateY(${translateY}px) scale(${scale})`;
    }
  }

  resetIcon(icon) {
    icon.style.opacity = '0';
    icon.style.transform = 'translateY(20px) scale(0.8)';
  }

  clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
  }

  destroy() {
    // Nettoyer l'event listener
    if (this.handleScrollBound) {
      window.removeEventListener('scroll', this.handleScrollBound);
    }
    
    // Réinitialiser les icônes
    this.icons.forEach(icon => {
      icon.style.opacity = '';
      icon.style.transform = '';
      icon.style.transition = '';
    });
  }
}

// Instance globale
let discoverIconsAnimationInstance = null;

/**
 * Initialiser l'animation des icônes
 */
function initDiscoverIconsAnimation() {
  // Nettoyer l'ancienne instance
  if (discoverIconsAnimationInstance) {
    discoverIconsAnimationInstance.destroy();
    discoverIconsAnimationInstance = null;
  }

  // Créer la nouvelle instance seulement si les icônes existent sur la page
  const iconsContainer = document.querySelector('.discover-icons');
  if (iconsContainer) {
    discoverIconsAnimationInstance = new DiscoverIconsAnimation();
  }
}

// Nettoyer avant de quitter la page
document.addEventListener('turbo:before-render', () => {
  if (discoverIconsAnimationInstance) {
    discoverIconsAnimationInstance.destroy();
    discoverIconsAnimationInstance = null;
  }
});

// Initialisation avec Turbo
document.addEventListener('turbo:load', initDiscoverIconsAnimation);

// Initialisation sans Turbo (chargement initial)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initDiscoverIconsAnimation);
} else {
  initDiscoverIconsAnimation();
}

export { DiscoverIconsAnimation };

