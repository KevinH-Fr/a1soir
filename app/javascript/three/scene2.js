import * as THREE from 'three';

let imageMeshes = [];
let logoMesh = null;
let logoReady = false;

// === CONFIGURABLE CONSTANTS ===
const baseScroll = 6000;               // When dresses begin appearing
const step = 500;                     // Scroll span per dress group
const dressScaleMin = 0.4;
const dressScaleMax = 1;

const logoStart = 5000;
const logoEnd = 6000;
const logoCenterScale = 5;
const logoCornerScale = 2;
const logoCornerPosition = { x: -2.5, y: 2.8 };

export function initScene2() {
  const container = document.getElementById('canvas2');

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

  // === Dress Images ===
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
    const geometry = new THREE.PlaneGeometry(4.5, 4.5);
    const mesh = new THREE.Mesh(geometry, material);

    mesh.position.set(6, -0.5, 0);
    mesh.scale.set(dressScaleMin, dressScaleMin, 1);

    const mainText = createTextSprite(`Main Title ${index + 1}`, 60, "#ffffff");
    const subText = createTextSprite(`Subtitle ${index + 1}`, 40, "#cccccc");

    mainText.position.set(2, 2.6, 0);
    subText.position.set(2, 2.2, 0);

    mainText.material.opacity = 0;
    subText.material.opacity = 0;

    mesh.add(mainText);
    mesh.add(subText);

    imageMeshes.push({ mesh, mainText, subText });
    scene.add(mesh);
  });

  // === Logo with aspect ratio
  textureLoader.load('images/logo_courant.png', (texture) => {
    const aspect = texture.image.width / texture.image.height;
    const baseHeight = 0.1;
    const baseWidth = baseHeight * aspect;

    const geometry = new THREE.PlaneGeometry(baseWidth, baseHeight);
    const material = new THREE.MeshBasicMaterial({ map: texture, transparent: true });

    logoMesh = new THREE.Mesh(geometry, material);
    logoMesh.visible = false;
    logoMesh.position.set(0, 0, 1);
    logoReady = true;

    scene.add(logoMesh);
  });

  window.addEventListener('scroll', () => onScroll());

  return { scene, camera, renderer };
}

// === Create text as a sprite
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
  const material = new THREE.SpriteMaterial({ map: texture, transparent: true });
  const sprite = new THREE.Sprite(material);

  const scale = 0.01 * fontSize;
  sprite.scale.set(canvas.width / canvas.height * scale, scale, 1);
  return sprite;
}

// === Logo Animation
function updateLogo(scrollY) {
  if (!logoReady || !logoMesh) return;

  if (scrollY < logoStart) {
    logoMesh.visible = false;
    return;
  }

  logoMesh.visible = true;

  if (scrollY <= logoEnd) {
    const t = (scrollY - logoStart) / (logoEnd - logoStart);
    const scale = t < 0.5
      ? THREE.MathUtils.lerp(1, logoCenterScale, t * 2)
      : THREE.MathUtils.lerp(logoCenterScale, logoCornerScale, (t - 0.5) * 2);

    const moveT = Math.max(0, (t - 0.5) * 2);
    const x = THREE.MathUtils.lerp(0, logoCornerPosition.x, moveT);
    const y = THREE.MathUtils.lerp(0, logoCornerPosition.y, moveT);

    logoMesh.scale.set(scale, scale, 1);
    logoMesh.position.set(x, y, 1);
    logoMesh.material.opacity = 1;
  } else {
    logoMesh.scale.set(logoCornerScale, logoCornerScale, 1);
    logoMesh.position.set(logoCornerPosition.x, logoCornerPosition.y, 1);
    logoMesh.material.opacity = 1;
  }
}

// === Main Scroll Logic
function onScroll() {
  const scrollY = window.scrollY;
  updateLogo(scrollY);

  imageMeshes.forEach(({ mesh, mainText, subText }, i) => {
    const start = baseScroll + i * step;
    const end = start + step * 2;

    if (scrollY >= start && scrollY <= start + step) {
      const t = (scrollY - start) / step;
      mesh.material.opacity = t;
      mesh.position.x = THREE.MathUtils.lerp(6, 0, t);
      mesh.position.y = THREE.MathUtils.lerp(-0.5, 0, t);
      mesh.scale.set(THREE.MathUtils.lerp(dressScaleMin, dressScaleMax, t), THREE.MathUtils.lerp(dressScaleMin, dressScaleMax, t), 1);

      mainText.material.opacity = t >= 0.7 ? (t - 0.7) / 0.3 : 0;
      subText.material.opacity = t >= 0.9 ? (t - 0.9) / 0.1 : 0;

    } else if (scrollY > start + step && scrollY < end - step) {
      mesh.material.opacity = 1;
      mesh.position.set(0, 0, 0);
      mesh.scale.set(dressScaleMax, dressScaleMax, 1);
      mainText.material.opacity = 1;
      subText.material.opacity = 1;

    } else if (scrollY >= end - step && scrollY <= end) {
      const t = (scrollY - (end - step)) / step;
      mesh.material.opacity = 1 - t;
      mesh.position.x = THREE.MathUtils.lerp(0, -6, t);
      mesh.position.y = THREE.MathUtils.lerp(0, -0.5, t);
      mesh.scale.set(THREE.MathUtils.lerp(dressScaleMax, dressScaleMin, t), THREE.MathUtils.lerp(dressScaleMax, dressScaleMin, t), 1);

      subText.material.opacity = t <= 0.3 ? 1 - (t / 0.3) : 0;
      mainText.material.opacity = t <= 0.7 ? 1 - (t / 0.7) : 0;

    } else {
      mesh.material.opacity = 0;
      mesh.position.set(6, -0.5, 0);
      mesh.scale.set(dressScaleMin, dressScaleMin, 1);
      mainText.material.opacity = 0;
      subText.material.opacity = 0;
    }
  });
}

