import * as THREE from 'three';

let imageMeshes = [];

export function initScene3() {
  const container = document.getElementById('canvas3');

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);

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

  const textureLoader = new THREE.TextureLoader();
  const imagePaths = [
    'images/dress.png',
    'images/dress2.png',
    'images/dress.png',
    'images/dress2.png',
    'images/dress.png',
  ];

  imagePaths.forEach((path, index) => {
    const texture = textureLoader.load(path);
    const material = new THREE.MeshBasicMaterial({ map: texture, transparent: true, opacity: 0 });
    const geometry = new THREE.PlaneGeometry(3, 3);
    const mesh = new THREE.Mesh(geometry, material);

    mesh.position.x = 5;

    // Create main and sub text
    const mainText = createTextSprite(`Main Title ${index + 1}`, 80, "#ffffff");
    const subText = createTextSprite(`Subtitle ${index + 1}`, 50, "#cccccc");

    mainText.position.set(0, -1.8, 0);
    subText.position.set(0, -2.2, 0);

    mainText.material.opacity = 0;
    subText.material.opacity = 0;

    mesh.add(mainText);
    mesh.add(subText);

    imageMeshes.push({ mesh, mainText, subText });
    scene.add(mesh);
  });

  window.addEventListener('scroll', () => onScroll());

  return { scene, camera, renderer };
}

function createTextSprite(message, fontSize = 100, color = "#ffffff") {
  const canvas = document.createElement('canvas');
  const context = canvas.getContext('2d');

  context.font = `${fontSize}px Arial`;
  const textWidth = context.measureText(message).width;

  canvas.width = textWidth;
  canvas.height = fontSize * 1.5;

  context.font = `${fontSize}px Arial`;
  context.fillStyle = color;
  context.textBaseline = 'top';
  context.fillText(message, 0, 0);

  const texture = new THREE.CanvasTexture(canvas);
  texture.minFilter = THREE.LinearFilter;
  texture.needsUpdate = true;

  const material = new THREE.SpriteMaterial({ map: texture, transparent: true });
  const sprite = new THREE.Sprite(material);

  const scale = 0.4;
  sprite.scale.set(canvas.width / canvas.height * scale, scale, 1);
  return sprite;
}

function onScroll() {
  const scrollY = window.scrollY;
  const baseScroll = 10000;
  const step = 1000;
  const visibleImagesAtOnce = 2;
  const imageDisplayWindow = step * visibleImagesAtOnce;

  for (let i = 0; i < imageMeshes.length; i++) {
    const { mesh, mainText, subText } = imageMeshes[i];

    const start = baseScroll + i * step;
    const end = start + imageDisplayWindow;

    const fadeInStart = start;
    const fadeInEnd = start + step;

    const visibleStart = fadeInEnd;
    const visibleEnd = end - step;

    const fadeOutStart = visibleEnd;
    const fadeOutEnd = end;

    if (scrollY >= fadeInStart && scrollY <= fadeInEnd) {
      const t = (scrollY - fadeInStart) / (fadeInEnd - fadeInStart);
      mesh.material.opacity = t;
      mesh.position.x = THREE.MathUtils.lerp(3, 0, t);
      mesh.position.y = THREE.MathUtils.lerp(-1, 0, t);

      mainText.material.opacity = t;
      subText.material.opacity = t;

    } else if (scrollY > visibleStart && scrollY < fadeOutStart) {
      mesh.material.opacity = 1;
      mesh.position.x = 0;
      mesh.position.y = 0;

      mainText.material.opacity = 1;
      subText.material.opacity = 1;

    } else if (scrollY >= fadeOutStart && scrollY <= fadeOutEnd) {
      const t = (scrollY - fadeOutStart) / (fadeOutEnd - fadeOutStart);
      mesh.material.opacity = 1 - t;
      mesh.position.x = THREE.MathUtils.lerp(0, -3, t);
      mesh.position.y = THREE.MathUtils.lerp(0, -1, t);

      mainText.material.opacity = 1 - t;
      subText.material.opacity = 1 - t;

    } else {
      mesh.material.opacity = 0;
      mesh.position.x = 3;
      mesh.position.y = -1;

      mainText.material.opacity = 0;
      subText.material.opacity = 0;
    }
  }
}

export function animateScene3() {
  // No continuous animation needed for now
}
