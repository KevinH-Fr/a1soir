import * as THREE from 'three';

let camera, renderer, scene;

const image1 = {
  path: 'images/image1.png',
  scrollStart: 0,
  scrollEnd: 1500,
  mesh: null,
  material: null,
  zOffset: 0,
  zoomTarget: { x: -1.9, y: -1, z: 1 } // stronger zoom (was 2.5)
};

const otherImages = [
  {
    path: 'images/image2.png',
    scrollStart: 1500,
    scrollEnd: 3000,
    mesh: null,
    material: null,
    zOffset: 0,
    zoomTarget: { x: 2.8, y: 1, z: 0.8 } // stronger zoom
  },
  {
    path: 'images/image3.png',
    scrollStart: 3000,
    scrollEnd: 4500,
    mesh: null,
    material: null,
    zOffset: 0,
    zoomTarget: { x: -1, y: -1, z: 1.2 } // stronger zoom
  }
];


const initialCameraZ = 5;

export function initScene1() {
  const container = document.getElementById('canvas1');
  scene = new THREE.Scene();

  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
  );
  camera.position.set(0, 0, initialCameraZ);

  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  container.appendChild(renderer.domElement);

  const textureLoader = new THREE.TextureLoader();

  // === IMAGE LOADING FUNCTION WITH "COVER" BEHAVIOR ===
  const loadImageCover = (img, isVisible = false) => {
    textureLoader.load(img.path, (texture) => {
      const screenHeight = 2 * Math.tan((camera.fov * Math.PI) / 360) * camera.position.z;
      const screenWidth = screenHeight * camera.aspect;

      const imgAspect = texture.image.width / texture.image.height;
      const screenAspect = screenWidth / screenHeight;

      let planeWidth, planeHeight;

      if (imgAspect > screenAspect) {
        // Image is wider → fit height, crop width
        planeHeight = screenHeight;
        planeWidth = screenHeight * imgAspect;
      } else {
        // Image is taller → fit width, crop height
        planeWidth = screenWidth;
        planeHeight = screenWidth / imgAspect;
      }

      const geometry = new THREE.PlaneGeometry(planeWidth, planeHeight);
      const material = new THREE.MeshBasicMaterial({
        map: texture,
        transparent: true,
        opacity: isVisible ? 1 : 0
      });

      const mesh = new THREE.Mesh(geometry, material);
      mesh.position.z = img.zOffset;

      img.mesh = mesh;
      img.material = material;

      scene.add(mesh);
    });
  };

  // === LOAD IMAGES ===
  loadImageCover(image1, true);
  otherImages.forEach((img) => loadImageCover(img, false));

  // === EVENTS ===
  window.addEventListener('scroll', onScroll);
  window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
    // Optionally, rescale planes on resize if needed
  });

  return { scene, camera, renderer };
}

function onScroll() {
  const scrollY = window.scrollY;

  // === FADE IMAGE 1 ===
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

  // === FADE OTHER IMAGES ===
  otherImages.forEach(({ scrollStart, scrollEnd, material }) => {
    if (!material) return;

    if (scrollY <= scrollStart || scrollY >= scrollEnd) {
      material.opacity = 0;
    } else {
      const mid = (scrollStart + scrollEnd) / 2;
      const t = scrollY < mid
        ? (scrollY - scrollStart) / (mid - scrollStart)
        : 1 - (scrollY - mid) / (scrollEnd - mid);
      material.opacity = t;
    }
  });

  // === CAMERA ZOOM & PAN (X, Y, Z) ===
  let targetPosition = { x: 0, y: 0, z: initialCameraZ };

  // Image 1 scroll-based zoom + pan
  if (scrollY >= image1.scrollStart && scrollY <= image1.scrollEnd) {
    const t = (scrollY - image1.scrollStart) / (image1.scrollEnd - image1.scrollStart);
    targetPosition.x = THREE.MathUtils.lerp(0, image1.zoomTarget.x, t);
    targetPosition.y = THREE.MathUtils.lerp(0, image1.zoomTarget.y, t);
    targetPosition.z = THREE.MathUtils.lerp(initialCameraZ, image1.zoomTarget.z, t);
  }

  // Other images
  otherImages.forEach((img) => {
    if (scrollY >= img.scrollStart && scrollY <= img.scrollEnd) {
      const t = (scrollY - img.scrollStart) / (img.scrollEnd - img.scrollStart);
      targetPosition.x = THREE.MathUtils.lerp(0, img.zoomTarget.x, t);
      targetPosition.y = THREE.MathUtils.lerp(0, img.zoomTarget.y, t);
      targetPosition.z = THREE.MathUtils.lerp(initialCameraZ, img.zoomTarget.z, t);
    }
  });

  camera.position.set(targetPosition.x, targetPosition.y, targetPosition.z);
}
