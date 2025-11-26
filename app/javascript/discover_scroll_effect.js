/**
 * Effets de scroll pour la section "Découvrez notre univers"
 * Animations progressives basées sur la position du scroll
 */
class DiscoverScrollEffect {
  constructor() {
    this.section = document.querySelector('[data-discover]');
    if (!this.section) return;
    
    this.items = Array.from(this.section.querySelectorAll('[data-discover-item]'));
    this.imageContainer = this.section.querySelector('.discover-image-container');
    this.images = this.imageContainer 
      ? Array.from(this.imageContainer.querySelectorAll('.discover-img'))
      : [];
    this.currentImageIndex = 0;
    this.handleScrollBound = this.handleScroll.bind(this);
    this.init();
  }

  init() {
    // Initialiser la première image comme active
    if (this.images.length > 0) {
      this.images.forEach((img, index) => {
        if (index === 0) {
          img.classList.add('discover-img-active');
          img.style.opacity = '1';
          img.style.transform = 'scale(1)';
          img.style.zIndex = '1';
        } else {
          img.classList.remove('discover-img-active');
          img.style.opacity = '0';
          img.style.transform = 'scale(1.1)';
          img.style.zIndex = '0';
        }
      });
      this.currentImageIndex = 0;
    }
    
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
    const rawScrollProgress = (windowHeight - rect.top) / (sectionHeight + windowHeight);
    
    // Retarder le début de l'animation : ne commence qu'après 20% de scroll dans la section
    const animationStartOffset = 0.2;
    const scrollProgress = rawScrollProgress < animationStartOffset 
      ? 0 
      : this.clamp((rawScrollProgress - animationStartOffset) / (1 - animationStartOffset), 0, 1);

    // Phase d'entrée : 0% à 30% du scroll (après le décalage)
    const entryPhaseEnd = 0.3;
    const entryProgress = this.clamp(scrollProgress / entryPhaseEnd, 0, 1);

    // Phase stable : 30% à 55% du scroll (complètement visible)
    const stablePhaseStart = 0.3;
    const stablePhaseEnd = 0.55;

    // Phase de sortie : 55% à 80% du scroll (disparition plus rapide)
    const exitPhaseStart = 0.55;
    const exitPhaseEnd = 0.8;
    const exitProgress = this.clamp((scrollProgress - exitPhaseStart) / (exitPhaseEnd - exitPhaseStart), 0, 1);

    // Changer l'image pendant le scroll dans la phase visible
    if (scrollProgress > 0 && scrollProgress <= exitPhaseStart && this.imageContainer) {
      this.updateImageByScroll(scrollProgress);
    }

    // Cacher le conteneur si tous les éléments sont complètement disparus
    const container = this.section.querySelector('.container');
    if (scrollProgress > exitPhaseEnd) {
      if (container) {
        container.style.opacity = '0';
        container.style.visibility = 'hidden';
      }
    } else if (scrollProgress > 0) {
      if (container) {
        container.style.opacity = '1';
        container.style.visibility = 'visible';
      }
    }

    // Appliquer les transformations à chaque item
    this.items.forEach((item, index) => {
      // Délai pour effet séquentiel
      const delay = index * 0.15;
      const adjustedEntryProgress = this.clamp(entryProgress - delay, 0, 1);
      const adjustedExitProgress = this.clamp(exitProgress - delay, 0, 1);

      if (scrollProgress > exitPhaseEnd) {
        // Complètement disparu - cacher les éléments
        const isImageContainer = item.classList.contains('discover-image-container');
        item.style.opacity = '0';
        item.style.visibility = 'hidden';
        if (isImageContainer) {
          item.style.transform = 'translate(-80px, -40px) scale(1.2)';
        } else {
          item.style.transform = 'translateY(-60px) scale(1.3)';
        }
        item.style.filter = 'blur(20px)';
      } else if (scrollProgress > exitPhaseStart) {
        // Phase de sortie (fumée)
        this.applyExitEffect(item, adjustedExitProgress);
        // S'assurer que visibility est visible pendant la transition
        item.style.visibility = 'visible';
      } else if (scrollProgress > 0) {
        // Phase d'entrée et phase stable
        item.style.visibility = 'visible';
        if (adjustedEntryProgress >= 1) {
          // Phase stable - complètement visible
          const isImageContainer = item.classList.contains('discover-image-container');
          item.style.opacity = '1';
          item.style.transform = isImageContainer ? 'translate(0, 0) scale(1)' : 'translateY(0) scale(1)';
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
    // Détecter si c'est le container d'image
    const isImageContainer = item.classList.contains('discover-image-container');
    
    const opacity = progress;
    
    if (isImageContainer) {
      // Animation horizontale pour le container d'image (depuis la gauche)
      const translateX = (1 - progress) * -60; // De -60px à 0
      const translateY = (1 - progress) * 20; // Légère descente
      
      item.style.opacity = opacity;
      item.style.transform = `translate(${translateX}px, ${translateY}px)`;
      item.style.filter = 'blur(0px)';
    } else {
      // Animation verticale pour les autres éléments
      const translateY = (1 - progress) * 40; // De 40px à 0
      
      item.style.opacity = opacity;
      item.style.transform = `translateY(${translateY}px)`;
      item.style.filter = 'blur(0px)';
    }
  }

  applyExitEffect(item, progress) {
    // Détecter si c'est le container d'image
    const isImageContainer = item.classList.contains('discover-image-container');
    
    const opacity = 1 - progress;
    const scale = 1 + (progress * 0.2); // Légère augmentation
    const blur = progress * 15; // Flou
    
    if (isImageContainer) {
      // Animation horizontale pour le container d'image (retour vers la gauche)
      const translateX = -progress * 80; // Vers la gauche
      const translateY = -progress * 40; // Légère montée
      
      item.style.opacity = opacity;
      item.style.transform = `translate(${translateX}px, ${translateY}px) scale(${scale})`;
      item.style.filter = `blur(${blur}px)`;
    } else {
      // Animation verticale pour les autres éléments
      const translateY = -progress * 60; // Monte jusqu'à -60px
      
      item.style.opacity = opacity;
      item.style.transform = `translateY(${translateY}px) scale(${scale})`;
      item.style.filter = `blur(${blur}px)`;
    }
  }

  resetItem(item) {
    const isImageContainer = item.classList.contains('discover-image-container');
    
    item.style.opacity = '0';
    item.style.visibility = 'hidden';
    
    if (isImageContainer) {
      item.style.transform = 'translate(-60px, 20px)';
      // Réinitialiser la première image comme active
      if (this.images.length > 0) {
        this.images.forEach((img, index) => {
          if (index === 0) {
            img.classList.add('discover-img-active');
            img.style.opacity = '1';
            img.style.transform = 'scale(1)';
          } else {
            img.classList.remove('discover-img-active');
            img.style.opacity = '0';
            img.style.transform = 'scale(1.1)';
          }
        });
        this.currentImageIndex = 0;
      }
    } else {
      item.style.transform = 'translateY(40px)';
    }
    item.style.filter = 'blur(0px)';
  }

  updateImageByScroll(scrollProgress) {
    if (!this.imageContainer || this.images.length === 0) return;
    
    // Calculer l'index de l'image basé sur la progression du scroll
    // Diviser la phase visible (0 à exitPhaseStart) en segments égaux
    const exitPhaseStart = 0.55;
    const visiblePhaseProgress = Math.min(scrollProgress / exitPhaseStart, 1);
    const imageSegmentLength = 1 / this.images.length;
    
    let targetImageIndex = Math.floor(visiblePhaseProgress / imageSegmentLength);
    if (targetImageIndex >= this.images.length) {
      targetImageIndex = this.images.length - 1;
    }
    
    // Si l'index a changé, faire la transition
    if (targetImageIndex !== this.currentImageIndex) {
      this.currentImageIndex = targetImageIndex;
      
      this.images.forEach((img, index) => {
        if (index === targetImageIndex) {
          img.classList.add('discover-img-active');
          img.style.opacity = '1';
          img.style.transform = 'scale(1)';
          img.style.zIndex = '1';
        } else {
          img.classList.remove('discover-img-active');
          img.style.opacity = '0';
          img.style.transform = 'scale(1.1)';
          img.style.zIndex = '0';
        }
      });
    }
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

