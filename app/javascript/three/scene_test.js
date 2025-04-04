import * as THREE from 'three';

document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("three-canvas");

  // === Scene, Camera, Renderer ===
  const scene = new THREE.Scene();

  const camera = new THREE.PerspectiveCamera(
    75,
    container.clientWidth / container.clientHeight,
    0.1,
    1000
  );
  camera.position.z = 5;

  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setSize(container.clientWidth, container.clientHeight);
  container.appendChild(renderer.domElement);

  // === Load Image Texture ===
  const textureLoader = new THREE.TextureLoader();
  const imageTexture = textureLoader.load(
    '/images/party.jpg', // Ensure this path is valid in your Rails public folder
    () => console.log("Image loaded."),
    undefined,
    (err) => console.error("Image failed to load:", err)
  );

  // === Image Plane ===
  const material = new THREE.MeshBasicMaterial({ map: imageTexture, transparent: true });
  const geometry = new THREE.PlaneGeometry(4, 2.5); // Adjust aspect ratio if needed
  const plane = new THREE.Mesh(geometry, material);
  scene.add(plane);

  // === Render Loop ===
  function animate() {
    requestAnimationFrame(animate);
    renderer.render(scene, camera);
  }

  animate();

  // === Resize Handling ===
  window.addEventListener("resize", () => {
    camera.aspect = container.clientWidth / container.clientHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(container.clientWidth, container.clientHeight);
  });
});
