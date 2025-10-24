import * as THREE from 'three';

/**
 * Scène de ciel étoilé pour la page d'accueil
 * Étoiles qui scintillent doucement
 */
class StarryNightScene {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;

    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.stars = [];
    this.clock = new THREE.Clock();
    
    // Variables pour les interactions
    this.mouse = { x: 0, y: 0 };
    this.targetCameraPosition = { x: 0, y: 0 };
    this.scrollPosition = 0;
    
    this.init();
    this.setupInteractions();
    this.animate();
    this.handleResize();
  }

  init() {
    // Scène
    this.scene = new THREE.Scene();
    
    // Caméra
    this.camera = new THREE.PerspectiveCamera(
      75,
      this.container.clientWidth / this.container.clientHeight,
      0.1,
      1000
    );
    this.camera.position.z = 5;

    // Renderer avec fond transparent (le CSS gère le gradient)
    this.renderer = new THREE.WebGLRenderer({ 
      alpha: true, 
      antialias: true 
    });
    this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.container.appendChild(this.renderer.domElement);

    // Créer uniquement les étoiles
    this.createStars();
  }

  setupInteractions() {
    // Suivi de la souris
    document.addEventListener('mousemove', (event) => {
      // Normaliser entre -1 et 1
      this.mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
      this.mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
      
      // Position cible de la caméra (inversé pour effet opposé)
      this.targetCameraPosition.x = -this.mouse.x * 2;
      this.targetCameraPosition.y = -this.mouse.y * 2;
    });

    // Suivi du scroll
    window.addEventListener('scroll', () => {
      this.scrollPosition = window.pageYOffset * 0.0005;
    });
  }

  createStars() {
    // Créer plusieurs groupes d'étoiles de tailles différentes
    const starGroups = [
      { count: 800, size: 0.015, color: 0xffffff, opacity: 0.8, speed: 1 },
      { count: 200, size: 0.025, color: 0xffd700, opacity: 0.6, speed: 1.5 },
      { count: 100, size: 0.035, color: 0xffffff, opacity: 0.9, speed: 0.8 }
    ];

    starGroups.forEach((group, groupIndex) => {
      const geometry = new THREE.BufferGeometry();
      const positions = new Float32Array(group.count * 3);
      const initialOpacities = new Float32Array(group.count);
      const phases = new Float32Array(group.count);

      for (let i = 0; i < group.count; i++) {
        // Position aléatoire dans l'espace
        positions[i * 3] = (Math.random() - 0.5) * 20;
        positions[i * 3 + 1] = (Math.random() - 0.5) * 20;
        positions[i * 3 + 2] = (Math.random() - 0.5) * 10 - 5;

        // Opacité initiale aléatoire
        initialOpacities[i] = Math.random() * 0.5 + 0.5;
        
        // Phase de scintillement aléatoire
        phases[i] = Math.random() * Math.PI * 2;
      }

      geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

      const material = new THREE.PointsMaterial({
        size: group.size,
        color: group.color,
        transparent: true,
        opacity: group.opacity,
        blending: THREE.AdditiveBlending,
        sizeAttenuation: true
      });

      const starField = new THREE.Points(geometry, material);
      
      // Stocker les données pour l'animation
      starField.userData = {
        initialOpacities,
        phases,
        speed: group.speed,
        baseOpacity: group.opacity
      };

      this.stars.push(starField);
      this.scene.add(starField);
    });
  }

  animate() {
    requestAnimationFrame(() => this.animate());

    const elapsedTime = this.clock.getElapsedTime();

    // Appliquer le mouvement de la caméra en douceur (lerp)
    this.camera.position.x += (this.targetCameraPosition.x - this.camera.position.x) * 0.05;
    this.camera.position.y += (this.targetCameraPosition.y - this.camera.position.y) * 0.05;

    // Animer le scintillement des étoiles
    this.stars.forEach((starField, index) => {
      const { initialOpacities, phases, speed, baseOpacity } = starField.userData;
      const positions = starField.geometry.attributes.position.array;

      // Rotation très lente du champ d'étoiles
      starField.rotation.y = elapsedTime * 0.01 * speed;

      // Appliquer le mouvement au scroll (plus ou moins selon le groupe)
      const scrollFactor = (index + 1) * 0.3;
      starField.position.y = this.scrollPosition * scrollFactor;
      
      // Rotation légère selon la souris (effet parallax)
      starField.rotation.x = this.mouse.y * 0.05 * (index + 1);
      starField.rotation.z = -this.mouse.x * 0.05 * (index + 1);

      // Simuler le scintillement en modifiant l'opacité
      for (let i = 0; i < positions.length / 3; i++) {
        const phase = phases[i];
        const twinkle = Math.sin(elapsedTime * speed + phase) * 0.3 + 0.7;
        
        // Mettre à jour subtilement la position Z pour un effet de profondeur
        positions[i * 3 + 2] += Math.sin(elapsedTime * 0.5 + phase) * 0.001;
      }

      starField.geometry.attributes.position.needsUpdate = true;

      // Variation de l'opacité globale pour le scintillement
      const globalTwinkle = Math.sin(elapsedTime * 0.5 + index) * 0.1 + 0.9;
      starField.material.opacity = baseOpacity * globalTwinkle;
    });

    // Rendre la scène (le fond est géré par CSS)
    this.renderer.render(this.scene, this.camera);
  }

  handleResize() {
    window.addEventListener('resize', () => {
      if (!this.container) return;

      this.camera.aspect = this.container.clientWidth / this.container.clientHeight;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
    });
  }

  destroy() {
    if (this.renderer) {
      this.container.removeChild(this.renderer.domElement);
      this.renderer.dispose();
    }
  }
}

// Initialiser la scène au chargement
document.addEventListener('turbo:load', () => {
  const threeContainer = document.getElementById('three-container');
  if (threeContainer) {
    new StarryNightScene('three-container');
  }
});

// Initialiser aussi au chargement normal (sans Turbo)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    const threeContainer = document.getElementById('three-container');
    if (threeContainer && !threeContainer.querySelector('canvas')) {
      new StarryNightScene('three-container');
    }
  });
} else {
  const threeContainer = document.getElementById('three-container');
  if (threeContainer && !threeContainer.querySelector('canvas')) {
    new StarryNightScene('three-container');
  }
}

export default StarryNightScene;
