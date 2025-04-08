import * as THREE from 'three';

let imagePlane1, imagePlane2;
let assetsLoaded = { image1: false, image2: false };
let fadeInProgress = { image1: false, image2: false };

let camera;
let zoomStart = 15000;
let zoomEnd = 20000;
const initialCameraZ = 5;
const minCameraZ = 2;

export function initScene4() {
  const container = document.getElementById('canvas4');
  const scene = new THREE.Scene();

  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.z = initialCameraZ;

  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  container.appendChild(renderer.domElement);

  const textureLoader = new THREE.TextureLoader();

  // Load img1 (background)
  textureLoader.load('images/img1.png', (texture1) => {
    const aspect1 = texture1.image.width / texture1.image.height;
    const geometry1 = new THREE.PlaneGeometry(aspect1 * 5, 5);
    texture1.anisotropy = renderer.capabilities.getMaxAnisotropy();
    const material1 = new THREE.MeshBasicMaterial({
      map: texture1,
      transparent: true,
      opacity: 0
    });

    imagePlane1 = new THREE.Mesh(geometry1, material1);
    imagePlane1.position.z = -0.1;
    scene.add(imagePlane1);

    assetsLoaded.image1 = true;
    fadeInProgress.image1 = true;
  });

  // Load img2 (foreground, small)
  textureLoader.load('images/img2.png', (texture2) => {
    const aspect2 = texture2.image.width / texture2.image.height;
    const geometry2 = new THREE.PlaneGeometry(aspect2 * 0.20, 0.20);
    texture2.anisotropy = renderer.capabilities.getMaxAnisotropy();
    const material2 = new THREE.MeshBasicMaterial({
      map: texture2,
      transparent: true,
      opacity: 0
    });

    imagePlane2 = new THREE.Mesh(geometry2, material2);
    imagePlane2.position.set(-1.38, 0.04, 0); // you can adjust position as needed
    scene.add(imagePlane2);

    assetsLoaded.image2 = true;
    fadeInProgress.image2 = true;
  });

  window.addEventListener('scroll', () => onScroll(camera));

  return { scene, camera, renderer };
}

function onScroll(camera) {
  const scrollY = window.scrollY;
  const zoomBoost = 2;

  if (scrollY >= zoomStart && scrollY <= zoomEnd) {
    const t = (scrollY - zoomStart) / (zoomEnd - zoomStart);
    const easedT = t * zoomBoost;

    // Zoom in
    camera.position.z = THREE.MathUtils.lerp(initialCameraZ, minCameraZ, easedT);

    // Pan left
    camera.position.x = THREE.MathUtils.lerp(0, -0.8, easedT);

    // Pan slightly upward
    camera.position.y = THREE.MathUtils.lerp(0, 0.04, easedT); // adjust 0.3 as needed
  } else if (scrollY > zoomEnd) {
    camera.position.z = minCameraZ;
    camera.position.x = -0.8;
    camera.position.y = 0.3;
  } else {
    camera.position.z = initialCameraZ;
    camera.position.x = 0;
    camera.position.y = 0;
  }
}


export function animateScene4() {
  const fadeSpeed = 0.01;

  if (fadeInProgress.image1 && imagePlane1?.material.opacity < 1) {
    imagePlane1.material.opacity += fadeSpeed;
    if (imagePlane1.material.opacity >= 1) {
      fadeInProgress.image1 = false;
    }
  }

  if (fadeInProgress.image2 && imagePlane2?.material.opacity < 1) {
    imagePlane2.material.opacity += fadeSpeed;
    if (imagePlane2.material.opacity >= 1) {
      fadeInProgress.image2 = false;
    }
  }
}
