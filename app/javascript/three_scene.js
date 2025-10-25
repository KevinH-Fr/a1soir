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
    this.shootingStars = [];
    this.clock = new THREE.Clock();
    this.starTexture = null;
    this.startTime = Date.now();
    this.appearanceDuration = 2000; // 2 secondes pour l'apparition
    this.lastShootingStarTime = 0;
    
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

    // Créer la texture ronde pour les étoiles
    this.createStarTexture();

    // Créer les étoiles
    this.createStars();
  }

  createStarTexture() {
    // Créer une texture canvas pour des étoiles rondes
    const canvas = document.createElement('canvas');
    canvas.width = 64;
    canvas.height = 64;
    const ctx = canvas.getContext('2d');

    // Dessiner un cercle dégradé (plus lumineux au centre)
    const gradient = ctx.createRadialGradient(32, 32, 0, 32, 32, 32);
    gradient.addColorStop(0, 'rgba(255, 255, 255, 1)');
    gradient.addColorStop(0.2, 'rgba(255, 255, 255, 0.8)');
    gradient.addColorStop(0.4, 'rgba(255, 255, 255, 0.4)');
    gradient.addColorStop(0.7, 'rgba(255, 255, 255, 0.1)');
    gradient.addColorStop(1, 'rgba(255, 255, 255, 0)');

    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, 64, 64);

    this.starTexture = new THREE.CanvasTexture(canvas);
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
      this.scrollPosition = window.pageYOffset * 0.002;
    });
  }

  createShootingStar() {
    // Position de départ aléatoire dans tout l'espace visible
    const startX = (Math.random() - 0.5) * 20;
    const startY = (Math.random() - 0.5) * 20;
    const startZ = (Math.random() - 0.5) * 10 - 3;

    // Direction aléatoire et variée
    const angle = Math.random() * Math.PI * 2; // Angle aléatoire
    const verticalBias = -0.3 - Math.random() * 0.7; // Tendance vers le bas
    
    const direction = new THREE.Vector3(
      Math.cos(angle) * (0.5 + Math.random() * 1),
      verticalBias,
      Math.sin(angle) * (0.3 + Math.random() * 0.4)
    ).normalize();

    // Créer une traînée avec effet de dégradé (points au lieu de ligne)
    const trailLength = 0.4 + Math.random() * 0.3; // Traînée entre 0.4 et 0.7
    const numPoints = 8; // Points pour l'effet de dégradé
    
    const positions = [];
    const colors = [];
    const sizes = [];
    const opacities = [];
    
    for (let i = 0; i < numPoints; i++) {
      const t = i / (numPoints - 1);
      
      // Position
      positions.push(
        startX - direction.x * t * trailLength,
        startY - direction.y * t * trailLength,
        startZ - direction.z * t * trailLength
      );
      
      // Couleur (blanc, l'opacité sera gérée séparément)
      colors.push(1, 1, 1);
      
      // Opacité décroissante (l'avant est à 100%, l'arrière à 15%)
      const opacity = 1 - (t * 0.85);
      opacities.push(opacity);
      
      // Taille décroissante de l'avant vers l'arrière
      const size = (1 - t * 0.7) * 0.2; // Taille plus grande à l'avant
      sizes.push(size);
    }

    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
    geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
    geometry.setAttribute('size', new THREE.Float32BufferAttribute(sizes, 1));
    geometry.setAttribute('opacity', new THREE.Float32BufferAttribute(opacities, 1));

    // Shader personnalisé pour gérer l'opacité par vertex
    const material = new THREE.ShaderMaterial({
      uniforms: {
        pointTexture: { value: this.starTexture }
      },
      vertexShader: `
        attribute float size;
        attribute float opacity;
        varying float vOpacity;
        varying vec3 vColor;
        
        void main() {
          vOpacity = opacity;
          vColor = color;
          vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
          gl_PointSize = size * (300.0 / -mvPosition.z);
          gl_Position = projectionMatrix * mvPosition;
        }
      `,
      fragmentShader: `
        uniform sampler2D pointTexture;
        varying float vOpacity;
        varying vec3 vColor;
        
        void main() {
          vec4 texColor = texture2D(pointTexture, gl_PointCoord);
          gl_FragColor = vec4(vColor, vOpacity * texColor.a);
        }
      `,
      transparent: true,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      vertexColors: true
    });

    const shootingStar = new THREE.Points(geometry, material);
    
    // Données pour l'animation
    shootingStar.userData = {
      direction: direction,
      speed: 0.06 + Math.random() * 0.06, // Vitesse plus variée
      startTime: this.clock.getElapsedTime(),
      lifetime: 1.5 + Math.random() * 1, // Durée de vie entre 1.5 et 2.5s
      initialOpacity: 1.0,
      numPoints: numPoints
    };

    this.shootingStars.push(shootingStar);
    this.scene.add(shootingStar);
  }

  createStars() {
    // Créer plusieurs groupes d'étoiles de tailles différentes
    const starGroups = [
      { count: 1000, size: 0.02, color: 0xffffff, opacity: 0.8, speed: 1 },
      { count: 300, size: 0.035, color: 0xffd700, opacity: 0.7, speed: 1.5 },
      { count: 150, size: 0.05, color: 0xffffff, opacity: 0.9, speed: 0.8 }
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
        size: group.size * 2, // Augmenter la taille pour mieux voir les étoiles rondes
        color: group.color,
        transparent: true,
        opacity: group.opacity, // Opacité de base
        blending: THREE.AdditiveBlending,
        sizeAttenuation: true,
        map: this.starTexture, // Texture ronde
        depthWrite: false
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
    const currentTime = Date.now();
    const timeSinceStart = currentTime - this.startTime;

    // Calculer le facteur d'apparition (0 à 1 sur la durée d'apparition)
    const appearanceFactor = Math.min(timeSinceStart / this.appearanceDuration, 1);
    // Utiliser une courbe ease-out pour une apparition plus naturelle
    const easedAppearance = appearanceFactor; // Simplifié pour le débogage

    // Appliquer le mouvement de la caméra en douceur (lerp)
    this.camera.position.x += (this.targetCameraPosition.x - this.camera.position.x) * 0.05;
    this.camera.position.y += (this.targetCameraPosition.y - this.camera.position.y) * 0.05;

    // Créer des étoiles filantes aléatoirement (toutes les 3-7 secondes)
    if (elapsedTime - this.lastShootingStarTime > 3 + Math.random() * 4) {
      this.createShootingStar();
      this.lastShootingStarTime = elapsedTime;
    }

    // Animer les étoiles filantes
    for (let i = this.shootingStars.length - 1; i >= 0; i--) {
      const shootingStar = this.shootingStars[i];
      const { direction, speed, startTime, lifetime, initialOpacity, numPoints } = shootingStar.userData;
      const age = elapsedTime - startTime;

      if (age > lifetime) {
        // Supprimer l'étoile filante si elle a dépassé sa durée de vie
        this.scene.remove(shootingStar);
        shootingStar.geometry.dispose();
        shootingStar.material.dispose();
        this.shootingStars.splice(i, 1);
      } else {
        // Déplacer l'étoile filante
        shootingStar.position.x += direction.x * speed;
        shootingStar.position.y += direction.y * speed;
        shootingStar.position.z += direction.z * speed;

        // Faire disparaître progressivement
        const fadeOutStart = lifetime * 0.6;
        if (age > fadeOutStart) {
          const fadeProgress = (age - fadeOutStart) / (lifetime - fadeOutStart);
          const fadeFactor = 1 - fadeProgress;
          
          // Mettre à jour l'opacité de chaque point
          const opacities = shootingStar.geometry.attributes.opacity.array;
          for (let j = 0; j < numPoints; j++) {
            const t = j / (numPoints - 1);
            const baseOpacity = 1 - (t * 0.85);
            opacities[j] = baseOpacity * fadeFactor;
          }
          shootingStar.geometry.attributes.opacity.needsUpdate = true;
        }
      }
    }

    // Animer le scintillement des étoiles
    this.stars.forEach((starField, index) => {
      const { initialOpacities, phases, speed, baseOpacity } = starField.userData;
      const positions = starField.geometry.attributes.position.array;

      // Rotation très lente du champ d'étoiles
      starField.rotation.y = elapsedTime * 0.01 * speed;

      // Appliquer le mouvement au scroll (plus ou moins selon le groupe)
      const scrollFactor = (index + 1) * 0.8;
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
      
      // Combiner l'opacité d'apparition avec le scintillement
      // Si l'apparition est terminée, utiliser l'opacité normale
      if (easedAppearance >= 1) {
        starField.material.opacity = baseOpacity * globalTwinkle;
      } else {
        starField.material.opacity = baseOpacity * globalTwinkle * easedAppearance;
      }
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
    // Nettoyer les étoiles filantes
    this.shootingStars.forEach(shootingStar => {
      this.scene.remove(shootingStar);
      shootingStar.geometry.dispose();
      shootingStar.material.dispose();
    });
    this.shootingStars = [];

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
