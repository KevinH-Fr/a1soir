import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';

let dressModel;
let modelMaterials = [];

export function initScene2() {
  const container = document.getElementById('canvas2');

  const scene = new THREE.Scene();

  const camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.z = 5;

  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  container.appendChild(renderer.domElement);

  const loader = new GLTFLoader();
  loader.load(
    'models/dress.glb',
    (gltf) => {
      dressModel = gltf.scene;
      dressModel.scale.set(3, 3, 3);
      dressModel.position.y = -3;

      dressModel.traverse((child) => {
        if (child.isMesh) {
          child.material.transparent = true;
          child.material.opacity = 1;
          modelMaterials.push(child.material);
        }
      });

      scene.add(dressModel);
    },
    undefined,
    (error) => {
      console.error('Error loading dress model:', error);
    }
  );

  return { scene, camera, renderer };
}

export function animateScene2(scene) {
    if (dressModel) {
      const scrollY = window.scrollY;
      const scrollThreshold = 7000; // Start accelerating after this Y
  
      const baseSpeed = 0.02;
      let rotationSpeed = baseSpeed;
  
      if (scrollY > scrollThreshold) {
        const scrollFactor = (scrollY - scrollThreshold) * 0.0001; // Adjust as needed
        rotationSpeed += scrollFactor;
      }
  
      dressModel.rotation.y += rotationSpeed;
    }
}
  
