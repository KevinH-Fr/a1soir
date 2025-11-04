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

    this.init();
    this.loadModel();
    this.animate();
    this.handleResize();
    this.listenToRotationSpeed();
  }

  init() {
    // Scène
    this.scene = new THREE.Scene();

    // Caméra
    const aspect = this.container.clientWidth / this.container.clientHeight;
    this.camera = new THREE.PerspectiveCamera(50, aspect, 0.1, 100);
    this.camera.position.set(0, 0.5, 4);
    this.camera.lookAt(0, 0.5, 0);

    // Renderer
    this.renderer = new THREE.WebGLRenderer({ 
      alpha: true, 
      antialias: true 
    });
    this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
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
        
        // Centrer le modèle
        this.model.position.x = -center.x;
        this.model.position.y = -center.y;
        this.model.position.z = -center.z;
        
        // Ajuster l'échelle pour que le modèle rentre bien dans la vue
        const maxDim = Math.max(size.x, size.y, size.z);
        const scale = 2.1 / maxDim; // Augmenté pour une robe plus grande
        this.model.scale.setScalar(scale);

        // Stocker l'échelle finale pour l'animation
        this.targetScale = scale;

        // Animation d'apparition avec scale
        this.model.scale.setScalar(0);
        
        this.scene.add(this.model);

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

    if (this.model && this.targetScale) {
      const zoomDuration = 1.5; // Durée du zoom
      const pauseDuration = 1.5; // Pause avant rotation
      const rotationStartTime = zoomDuration + pauseDuration; // 3 secondes

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
        this.model.rotation.y = rotationTime * 0.15 * this.rotationSpeedMultiplier;
        
        // Debug: afficher une seule fois quand la rotation commence
        if (!this.rotationStarted) {
          this.rotationStarted = true;
          console.log('🔄 Rotation started! Multiplier:', this.rotationSpeedMultiplier);
        }
      }
    }

    // Mettre à jour le mixer d'animation si présent
    if (this.mixer) {
      this.mixer.update(delta);
    }

    if (this.renderer && this.scene && this.camera) {
      this.renderer.render(this.scene, this.camera);
    }
  }

  listenToRotationSpeed() {
    window.addEventListener('dress-rotation-speed', (event) => {
      this.rotationSpeedMultiplier = event.detail.multiplier;
      console.log('✅ Rotation speed updated:', this.rotationSpeedMultiplier);
    });
  }

  handleResize() {
    this.resizeHandler = () => {
      if (!this.container) return;

      this.camera.aspect = this.container.clientWidth / this.container.clientHeight;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
    };
    window.addEventListener('resize', this.resizeHandler);
  }

  destroy() {
    // Nettoyer les event listeners
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler);
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

