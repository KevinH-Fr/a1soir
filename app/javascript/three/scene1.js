import * as THREE from 'three';

let camera, renderer, scene;

const image1 = {
  path: 'images/image1.png',
  scrollStart: 0,
  scrollEnd: 1000,
  mesh: null,
  material: null,
  zOffset: -0.1
};

const otherImages = [
  {
    path: 'images/image2.png',
    scrollStart: 1000,
    scrollEnd: 2000,
    mesh: null,
    material: null,
    zOffset: 0
  },
  {
    path: 'images/image3.png',
    scrollStart: 2000,
    scrollEnd: 3000,
    mesh: null,
    material: null,
    zOffset: 0.1
  }
];

const initialCameraZ = 5;
const minCameraZ = 2;

export function initScene1() {
  const container = document.getElementById('canvas1');
  scene = new THREE.Scene();

  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.z = initialCameraZ;

  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  container.appendChild(renderer.domElement);

  const textureLoader = new THREE.TextureLoader();

  // === IMAGE 1 ===
  textureLoader.load(image1.path, (texture) => {
    const aspect = texture.image.width / texture.image.height;
    const geometry = new THREE.PlaneGeometry(aspect * 5, 5);
    const material = new THREE.MeshBasicMaterial({
      map: texture,
      transparent: true,
      opacity: 1 // fully visible at start
    });
    const mesh = new THREE.Mesh(geometry, material);
    mesh.position.z = image1.zOffset;

    image1.mesh = mesh;
    image1.material = material;

    scene.add(mesh);
  });

  // === OTHER IMAGES ===
  otherImages.forEach((img) => {
    textureLoader.load(img.path, (texture) => {
      const aspect = texture.image.width / texture.image.height;
      const geometry = new THREE.PlaneGeometry(aspect * 5, 5);
      const material = new THREE.MeshBasicMaterial({
        map: texture,
        transparent: true,
        opacity: 0 // hidden at start
      });

      const mesh = new THREE.Mesh(geometry, material);
      mesh.position.z = img.zOffset;

      img.mesh = mesh;
      img.material = material;

      scene.add(mesh);
    });
  });

  window.addEventListener('scroll', onScroll);
  window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });

  return { scene, camera, renderer };
}

function onScroll() {
  const scrollY = window.scrollY;

  // === IMAGE 1: fade out and zoom ===
  if (image1.material) {
    if (scrollY <= image1.scrollStart) {
      image1.material.opacity = 1;
    } else if (scrollY >= image1.scrollEnd) {
      image1.material.opacity = 0;
    } else {
      const t = (scrollY - image1.scrollStart) / (image1.scrollEnd - image1.scrollStart);
      image1.material.opacity = 1 - t;
    }
  }

  // === OTHER IMAGES: fade in then fade out ===
  otherImages.forEach(({ scrollStart, scrollEnd, material }) => {
    if (!material) return;

    if (scrollY <= scrollStart) {
      material.opacity = 0;
    } else if (scrollY >= scrollEnd) {
      material.opacity = 0;
    } else {
      const mid = (scrollStart + scrollEnd) / 2;
      if (scrollY < mid) {
        const t = (scrollY - scrollStart) / (mid - scrollStart);
        material.opacity = t;
      } else {
        const t = (scrollY - mid) / (scrollEnd - mid);
        material.opacity = 1 - t;
      }
    }
  });

  // === ZOOM: active image based ===
  let currentZoom = initialCameraZ;

  // Image 1 zoom
  if (scrollY >= image1.scrollStart && scrollY <= image1.scrollEnd) {
    const t = (scrollY - image1.scrollStart) / (image1.scrollEnd - image1.scrollStart);
    currentZoom = THREE.MathUtils.lerp(initialCameraZ, minCameraZ, t);
  }

  // Other images zoom
  otherImages.forEach(({ scrollStart, scrollEnd }) => {
    if (scrollY >= scrollStart && scrollY <= scrollEnd) {
      const t = (scrollY - scrollStart) / (scrollEnd - scrollStart);
      currentZoom = THREE.MathUtils.lerp(initialCameraZ, minCameraZ, t);
    }
  });

  camera.position.z = currentZoom;
}

export function animateScene1() {
  // Scroll-driven animation
}
