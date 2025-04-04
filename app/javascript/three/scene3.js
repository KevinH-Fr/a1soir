import * as THREE from 'three';

export function initScene3() {
  const container = document.getElementById('canvas3');

  // Create scene
  const scene = new THREE.Scene();

  // Create camera
  const camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.z = 5;

  // Create renderer
  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  container.appendChild(renderer.domElement);

  // Add objects specific to Scene 3
  const geometry = new THREE.ConeGeometry(1, 2, 32);
  const material = new THREE.MeshBasicMaterial({ color: 0x0000ff });
  const cone = new THREE.Mesh(geometry, material);
  scene.add(cone);

  return { scene, camera, renderer };
}

export function animateScene3(scene) {
  // Rotate the cone
  scene.children.forEach((child) => {
    if (child instanceof THREE.Mesh) {
      child.rotation.x += 0.01;
      child.rotation.y += 0.01;
    }
  });
}
