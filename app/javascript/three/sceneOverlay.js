import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';

let scene, camera, renderer, model;
let modelMaterials = [];

let fadeInProgress = 0;

let lastScrollY = window.scrollY;
let currentDirection = 1; // 1 = right, -1 = left
let currentSpeed = 0;
let targetSpeed = 0;

export function initSceneOverlay() {
  const container = document.getElementById('canvasOverlay');
  scene = new THREE.Scene();

  camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 100);
  camera.position.set(0, 0, 5);

  renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  container.appendChild(renderer.domElement);

  const ambientLight = new THREE.AmbientLight(0xffffff, 1);
  scene.add(ambientLight);

  const loader = new GLTFLoader();
  loader.load('models/dress2.glb', (gltf) => {
    model = gltf.scene;
    model.scale.set(0.4, 0.4, 0.4);
    model.position.set(1.9, -1.8, 0);

    model.traverse((child) => {
      if (child.isMesh && child.material) {
        child.material.transparent = true;
        child.material.opacity = 0;
        modelMaterials.push(child.material);
      }
    });

    scene.add(model);
    fadeInProgress = 0;
  });

  window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });

  return { scene, camera, renderer };
}

export function animateSceneOverlay() {
  const scrollY = window.scrollY;

  if (model) {
    // === Fade in ===
    if (fadeInProgress < 1) {
      fadeInProgress += 0.01;
      modelMaterials.forEach((mat) => {
        mat.opacity = Math.min(1, fadeInProgress);
      });
    }

    // === Determine direction ===
    if (scrollY > lastScrollY) {
      currentDirection = 1; // scroll down
    } else if (scrollY < lastScrollY) {
      currentDirection = -1; // scroll up
    }

    // === Compute speed from scroll position (no max cap) ===
    const baseSpeed = 0.002;
    const scrollFactor = scrollY * 0.00005; // tweak multiplier to control sensitivity
    targetSpeed = baseSpeed + scrollFactor;

    // Smooth transition
    currentSpeed = THREE.MathUtils.lerp(currentSpeed, targetSpeed, 0.05);

    model.rotation.y += currentDirection * currentSpeed;

    lastScrollY = scrollY;
  }

  renderer.render(scene, camera);
}
