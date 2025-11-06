import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';

class DressModel {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;

    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.model = null;
    this.clock = new THREE.Clock();
    this.mixer = null;
    this.targetScale = null;
    this.rotationSpeedMultiplier = 1; // Multiplicateur de vitesse de rotation
    this.rotationStarted = false; // Pour le debug
    this.rafId = null;
    this.scrollProgress = 0; // Progression du scroll (0 = début, 1 = centre atteint)
    this.modelCenterOffset = { x: 0, y: 0, z: 0 }; // Offset pour centrer le modèle
    this.modelSize = null; // Taille réelle du modèle (pour maintenir le ratio)

    this.init();
    this.loadModel();
    this.animate();
    this.handleResize();
    this.handleScroll();
  }

  init() {
    // Scène
    this.scene = new THREE.Scene();

    // Utiliser la taille de la fenêtre entière
    const width = window.innerWidth;
    const height = window.innerHeight;
    const aspect = width / height;
    
    this.camera = new THREE.PerspectiveCamera(50, aspect, 0.1, 100);
    
    // Position de la caméra adaptée à la taille de l'écran
    this.updateCameraDistance();
    this.camera.lookAt(0, 0, 0);

    // Renderer
    this.renderer = new THREE.WebGLRenderer({ 
      alpha: true, 
      antialias: true 
    });
    this.renderer.setSize(width, height);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.2;
    this.container.appendChild(this.renderer.domElement);

    // Lumières
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.8);
    this.scene.add(ambientLight);

    const directionalLight = new THREE.DirectionalLight(0xffffff, 1.5);
    directionalLight.position.set(2, 3, 2);
    this.scene.add(directionalLight);

    const directionalLight2 = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight2.position.set(-2, 1, -2);
    this.scene.add(directionalLight2);

    // Lumière de remplissage
    const fillLight = new THREE.HemisphereLight(0xffffff, 0x444444, 0.6);
    this.scene.add(fillLight);
  }

  loadModel() {
    const loader = new GLTFLoader();
    
    // Utiliser le chemin des images dans app/assets/images
    loader.load(
      '/images/dress.glb',
      (gltf) => {
        this.model = gltf.scene;
        
        // Centrer et ajuster la taille du modèle
        const box = new THREE.Box3().setFromObject(this.model);
        const center = box.getCenter(new THREE.Vector3());
        const size = box.getSize(new THREE.Vector3());
        const min = box.min;
        const max = box.max;
        
        // Stocker la taille réelle du modèle pour maintenir le ratio
        this.modelSize = { width: size.x, height: size.y, depth: size.z };
        
        // Pour une robe, centrer visuellement en utilisant le centre géométrique
        // Ajustement manuel pour le centrage vertical (en unités Three.js)
        // Valeur positive = déplacer vers le haut, valeur négative = déplacer vers le bas
        const verticalAdjustment = 0; // Ajustez cette valeur pour centrer visuellement la robe
        
        // Le centre Y devrait placer le modèle au centre vertical de l'écran (Y=0)
        this.modelCenterOffset = { 
          x: -center.x, 
          y: -center.y + verticalAdjustment, 
          z: -center.z 
        };
                
        // Pas de scale - utiliser la taille originale du modèle
        // this.targetScale sera null pour désactiver l'animation de zoom
        this.targetScale = null;
        
        this.scene.add(this.model);
        
        // Mettre à jour la distance de la caméra pour respecter le ratio
        this.updateCameraDistance();
        
        // Positionner le modèle à sa position initiale (gauche, centré verticalement)
        this.updateModelPosition();

        // Si le modèle a des animations
        if (gltf.animations && gltf.animations.length > 0) {
          this.mixer = new THREE.AnimationMixer(this.model);
          gltf.animations.forEach((clip) => {
            this.mixer.clipAction(clip).play();
          });
        }
      },
      (progress) => {
        console.log('Chargement du modèle:', (progress.loaded / progress.total * 100) + '%');
      },
      (error) => {
        console.error('Erreur de chargement du modèle:', error);
      }
    );
  }

  animate() {
    this.rafId = requestAnimationFrame(() => this.animate());

    // Garde-fous si l'animation continue après destruction/changement de page
    if (!this.renderer || !this.scene || !this.camera) {
      return;
    }

    const elapsedTime = this.clock.getElapsedTime();
    const delta = this.clock.getDelta();

    if (this.model) {
      if (this.targetScale) {
        // Animation avec scale (ancien comportement)
        const zoomDuration = 1.5; // Durée du zoom initial
        const pauseDuration = 0.5; // Pause avant rotation
        const rotationStartTime = zoomDuration + pauseDuration;

        if (elapsedTime < zoomDuration) {
          // Animation de zoom pendant 1.5s
          const progress = elapsedTime / zoomDuration;
          const eased = 1 - Math.pow(1 - progress, 3); // ease-out
          this.model.scale.setScalar(this.targetScale * eased);
        } else if (elapsedTime < rotationStartTime) {
          // Pause - la robe reste immobile
          this.model.scale.setScalar(this.targetScale);
        } else {
          // S'assurer que le scale final est correct
          this.model.scale.setScalar(this.targetScale);
          // Rotation douce continue avec accélération au scroll
          const rotationTime = elapsedTime - rotationStartTime;
          this.model.rotation.y = rotationTime * 0.25 * this.rotationSpeedMultiplier;
          
          // Debug: afficher une seule fois quand la rotation commence
          if (!this.rotationStarted) {
            this.rotationStarted = true;
            console.log('🔄 Rotation started! Multiplier:', this.rotationSpeedMultiplier);
          }
        }
      } else {
        // Pas de scale - rotation directe
        const pauseDuration = 0.5; // Pause avant rotation
        if (elapsedTime > pauseDuration) {
          const rotationTime = elapsedTime - pauseDuration;
          this.model.rotation.y = rotationTime * 0.25 * this.rotationSpeedMultiplier;
          
          // Debug: afficher une seule fois quand la rotation commence
          if (!this.rotationStarted) {
            this.rotationStarted = true;
            console.log('🔄 Rotation started! Multiplier initial:', this.rotationSpeedMultiplier.toFixed(2));
          }
        }
      }

      // Déplacement horizontal basé sur le scroll
      // scrollProgress: 0 = gauche, 1 = centre
      this.updateModelPosition();
      
      // Appliquer l'effet de fumée à la fin du scroll
      this.applySmokeEffect();
    }

    // Mettre à jour le mixer d'animation si présent
    if (this.mixer) {
      this.mixer.update(delta);
    }

    if (this.renderer && this.scene && this.camera) {
      this.renderer.render(this.scene, this.camera);
    }
  }

  handleResize() {
    this.resizeHandler = () => {
      if (!this.renderer || !this.camera) return;

      const width = window.innerWidth;
      const height = window.innerHeight;
      
      this.camera.aspect = width / height;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(width, height);
      
      // Recalculer la distance de la caméra
      this.updateCameraDistance();
      
      // Mettre à jour la position du modèle
      this.updateModelPosition();
    };
    window.addEventListener('resize', this.resizeHandler);
  }

  handleScroll() {
    this.scrollHandler = () => {
      // Calculer la progression du scroll
      const scrollY = window.scrollY;
      const windowHeight = window.innerHeight;
      
      // La robe se déplace pendant les 800 premiers pixels de scroll
      const scrollDistance = 800;
      this.scrollProgress = Math.min(scrollY / scrollDistance, 1);
      
      // Calculer l'accélération de rotation basée sur le scroll
      // Plus on scroll, plus la rotation s'accélère (de 1x à 5x)
      const rotationAcceleration = 1 + (this.scrollProgress * 4); // De 1 à 5
      this.rotationSpeedMultiplier = rotationAcceleration;
    };
    
    window.addEventListener('scroll', this.scrollHandler);
  }

  updateCameraDistance() {
    if (!this.camera) return;
    
    // Si le modèle n'est pas encore chargé, utiliser des valeurs par défaut
    if (!this.modelSize) {
      return;
    }

    // Taille désirée de la robe à l'écran (en pourcentage de la hauteur du viewport)
    const desiredHeightRatio = 0.6;
    
    // Utiliser la taille réelle du modèle
    const modelHeight = this.modelSize.height;
    const modelWidth = this.modelSize.width;
    const modelAspectRatio = modelWidth / modelHeight; // Ratio largeur/hauteur du modèle
    
    const fov = this.camera.fov * (Math.PI / 180);
    const screenAspect = window.innerWidth / window.innerHeight;
    
    // Calculer la distance pour que la hauteur du modèle occupe desiredHeightRatio de l'écran
    const distanceForHeight = (modelHeight / desiredHeightRatio) / (2 * Math.tan(fov / 2));
    
    // Avec cette distance, calculer quelle largeur sera visible à l'écran
    const visibleWidthAtDistance = 2 * Math.tan(fov / 2) * distanceForHeight * screenAspect;
    
    // Calculer quelle largeur du modèle sera visible à cette distance (le modèle garde son ratio)
    const modelWidthVisible = modelWidth;
    
    // Si la largeur du modèle dépasse ce qui est visible, on doit reculer la caméra
    // pour que la largeur rentre, tout en préservant le ratio du modèle
    let distance;
    if (modelWidthVisible > visibleWidthAtDistance) {
      // Le modèle est plus large que l'écran, ajuster la distance pour que la largeur rentre
      // On calcule la distance pour que la largeur occupe desiredHeightRatio de la largeur de l'écran
      const desiredWidthRatio = desiredHeightRatio; // Même ratio pour la cohérence
      distance = (modelWidth / desiredWidthRatio) / (2 * Math.tan(fov / 2) * screenAspect);
    } else {
      // Le modèle rentre en largeur, utiliser la distance basée sur la hauteur
      // Le ratio est préservé car on ne scale pas le modèle, seulement la distance
      distance = distanceForHeight;
    }
    
    this.camera.position.set(0, 0, distance);
    this.camera.lookAt(0, 0, 0);
    this.camera.updateProjectionMatrix();
  }

  updateModelPosition() {
    if (!this.model || !this.camera) return;

    // Calculer le déplacement horizontal en fonction de la taille de l'écran
    const fov = this.camera.fov * (Math.PI / 180);
    const distance = this.camera.position.z;
    const aspect = window.innerWidth / window.innerHeight;
    
    // Largeur visible à la distance du modèle
    const visibleWidth = 2 * Math.tan(fov / 2) * distance * aspect;
    
    // Position initiale : à gauche mais centrée verticalement
    const startX = -visibleWidth * 0.25; // 25% vers la gauche (moins à gauche qu'avant)
    
    // Position finale : au centre horizontal et vertical
    const endX = 0;
    
    // Interpolation avec easing (seulement horizontal maintenant)
    const eased = 1 - Math.pow(1 - this.scrollProgress, 3); // ease-out
    const currentX = startX + (endX - startX) * eased;
    
    // Appliquer la position
    // On utilise l'offset X, Y et Z pour centrer le modèle
    // L'offset Y compense le décalage du centre géométrique pour centrer verticalement
    this.model.position.set(
      currentX + this.modelCenterOffset.x,
      this.modelCenterOffset.y, // Centre vertical de l'écran
      this.modelCenterOffset.z
    );
  }

  applySmokeEffect() {
    if (!this.model) return;
    
    // L'effet de fumée commence quand scrollProgress atteint 0.8
    const smokeStartThreshold = 0.8;
    
    if (this.scrollProgress < smokeStartThreshold) {
      // Pas encore de fumée, s'assurer que le modèle est visible et au scale normal
      this.model.traverse((child) => {
        if (child.isMesh && child.material) {
          const material = Array.isArray(child.material) ? child.material[0] : child.material;
          if (material) {
            material.opacity = 1.0;
            material.transparent = false;
          }
        }
      });
      // Remettre le scale à la normale
      const baseScale = this.targetScale || 1;
      this.model.scale.setScalar(baseScale);
      this.model.visible = true;
      return;
    }
    
    // Calculer la progression de la fumée (0 = début fumée, 1 = complètement disparu)
    const smokeProgress = (this.scrollProgress - smokeStartThreshold) / (1 - smokeStartThreshold);
    
    // Opacité qui diminue progressivement
    const opacity = 1 - smokeProgress;
    
    // Scale qui augmente légèrement pour simuler la dispersion
    const scaleFactor = 1 + (smokeProgress * 0.3); // Jusqu'à 1.3x
    
    // Appliquer l'effet à tous les matériaux du modèle
    this.model.traverse((child) => {
      if (child.isMesh && child.material) {
        const materials = Array.isArray(child.material) ? child.material : [child.material];
        materials.forEach((material) => {
          if (material) {
            material.opacity = opacity;
            material.transparent = true;
            // Activer la transparence si nécessaire
            if (opacity < 1) {
              material.needsUpdate = true;
            }
          }
        });
      }
    });
    
    // Appliquer le scale au modèle entier pour l'effet de dispersion
    // Le scale initial du modèle est 1 (pas de scale appliqué), donc on applique juste le facteur de fumée
    const baseScale = this.targetScale || 1;
    this.model.scale.setScalar(baseScale * scaleFactor);
    
    // Masquer complètement le modèle quand il est invisible
    if (opacity <= 0) {
      this.model.visible = false;
    } else {
      this.model.visible = true;
    }
  }

  destroy() {
    // Nettoyer les event listeners
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler);
    }
    if (this.scrollHandler) {
      window.removeEventListener('scroll', this.scrollHandler);
    }
    // Stopper la boucle d'animation
    if (this.rafId) {
      cancelAnimationFrame(this.rafId);
      this.rafId = null;
    }
    
    // Nettoyer les ressources Three.js
    if (this.renderer) {
      this.renderer.dispose();
      if (this.renderer.domElement && this.renderer.domElement.parentNode) {
        this.renderer.domElement.parentNode.removeChild(this.renderer.domElement);
      }
    }
    
    if (this.scene) {
      this.scene.clear();
    }
    
    // Nettoyer les références
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.model = null;
    this.container = null;
  }
}

// Instance globale
let dressModelInstance = null;

function initDressModel() {
  const dressContainer = document.getElementById('dress-model-container');
  
  // Si le conteneur existe
  if (dressContainer) {
    // Si une instance existe déjà et que le conteneur est différent, détruire l'ancienne
    if (dressModelInstance && dressModelInstance.container !== dressContainer) {
      console.log('🗑️ Destruction de l\'ancienne instance du modèle 3D');
      dressModelInstance.destroy();
      dressModelInstance = null;
    }
    
    // Créer une nouvelle instance si nécessaire
    if (!dressModelInstance) {
      console.log('🎨 Création d\'une nouvelle instance du modèle 3D');
      dressModelInstance = new DressModel('dress-model-container');
    }
  } else {
    // Si le conteneur n'existe pas et qu'une instance existe, la détruire
    if (dressModelInstance) {
      console.log('🗑️ Destruction de l\'instance (conteneur introuvable)');
      dressModelInstance.destroy();
      dressModelInstance = null;
    }
  }
}

// Nettoyer avant de quitter la page
document.addEventListener('turbo:before-render', () => {
  if (dressModelInstance) {
    console.log('🧹 Nettoyage avant changement de page');
    dressModelInstance.destroy();
    dressModelInstance = null;
  }
});

// Initialiser après le chargement de la page
document.addEventListener('turbo:load', initDressModel);

// Pour le chargement initial sans Turbo
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initDressModel);
} else {
  initDressModel();
}

export default DressModel;

