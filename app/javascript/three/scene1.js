import * as THREE from 'three';

let imagePlane, textSprite1, textSprite2, sequentialTextSprite;
let assetsLoaded = { image: false, text1: false, text2: false, sequentialText: false };
let fadeInProgress = { image: false, text1: false, text2: false };

const words = ["Word1", "Word2", "Word3", "Word4", "Word5"];
const scrollPositions = [1200, 1700, 2200, 2700, 3200];

let camera;
let zoomStart = 1000;
let zoomEnd = 4000;
const initialCameraZ = 5;
const minCameraZ = 2;

export function initScene1() {
  const container = document.getElementById('canvas1');
  const scene = new THREE.Scene();
  camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
  camera.position.z = initialCameraZ;

  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  container.appendChild(renderer.domElement);

  // Load texture and image plane
  const textureLoader = new THREE.TextureLoader();
  textureLoader.load(
    'images/party.jpg',
    (texture) => {
      const aspect = texture.image.width / texture.image.height;
      const geometry = new THREE.PlaneGeometry(aspect * 5, 5);
      texture.anisotropy = renderer.capabilities.getMaxAnisotropy();
      const material = new THREE.MeshBasicMaterial({ map: texture, transparent: true, opacity: 0 });
      imagePlane = new THREE.Mesh(geometry, material);
      scene.add(imagePlane);
      assetsLoaded.image = true;
      fadeInProgress.image = true;
    }
  );

  // Sprite creation helper
  const createTextSprite = (message, fontSize, color, yPosition) => {
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');
    const scaleFactor = 4;
    const padding = 10 * scaleFactor;
    context.font = `${fontSize * scaleFactor}px Arial`;
    const textWidth = context.measureText(message).width;
    canvas.width = textWidth + padding * 2;
    canvas.height = fontSize * scaleFactor + padding * 2;
    context.scale(scaleFactor, scaleFactor);
    context.font = `${fontSize}px Arial`;
    context.fillStyle = color;
    context.textAlign = 'center';
    context.textBaseline = 'middle';
    context.fillText(message, canvas.width / (2 * scaleFactor), canvas.height / (2 * scaleFactor));
    const texture = new THREE.CanvasTexture(canvas);
    texture.anisotropy = renderer.capabilities.getMaxAnisotropy();
    const spriteMaterial = new THREE.SpriteMaterial({ map: texture, transparent: true, opacity: 0 });
    const sprite = new THREE.Sprite(spriteMaterial);
    sprite.scale.set(4, 2, 1);
    sprite.position.set(0, yPosition, 0.1);
    scene.add(sprite);
    return sprite;
  };

  textSprite1 = createTextSprite("AUTOUR D'UN SOIR", 48, 'white', 1.5);
  textSprite2 = createTextSprite('Mariage et Tenues de soirée', 24, 'white', 0.5);
  sequentialTextSprite = createTextSprite('', 36, 'white', -1.5);
  assetsLoaded.sequentialText = true;

  window.addEventListener('scroll', () => onScroll(camera));

  return { scene, camera, renderer };
}

function updateTextSprite(sprite, message) {
  const canvas = document.createElement('canvas');
  const context = canvas.getContext('2d');
  const fontSize = 36;
  const padding = 10;
  context.font = `${fontSize}px Arial`;
  const textWidth = context.measureText(message).width;
  canvas.width = textWidth + padding * 2;
  canvas.height = fontSize + padding * 2;
  context.font = `${fontSize}px Arial`;
  context.fillStyle = 'white';
  context.textAlign = 'center';
  context.textBaseline = 'middle';
  context.fillText(message, canvas.width / 2, canvas.height / 2);
  const texture = new THREE.CanvasTexture(canvas);
  sprite.material.map = texture;
  sprite.material.needsUpdate = true;
}

function onScroll(camera) {
  const scrollY = window.scrollY;

  const fadeStart = 300;
  const fadeEnd = 1000;
  let opacity = 1;
  if (scrollY >= fadeStart) {
    opacity = 1 - (scrollY - fadeStart) / (fadeEnd - fadeStart);
    opacity = Math.max(0, opacity);
  }

  if (assetsLoaded.text1) textSprite1.material.opacity = opacity;
  if (assetsLoaded.text2) textSprite2.material.opacity = opacity;

  if (scrollY > fadeEnd) {
    sequentialTextSprite.material.opacity = 1;

    for (let i = 0; i < scrollPositions.length; i++) {
      if (scrollY >= scrollPositions[i] && (i === scrollPositions.length - 1 || scrollY < scrollPositions[i + 1])) {
        updateTextSprite(sequentialTextSprite, words[i]);

        // Animate scale for eye-open/eye-close
        const effectStart = scrollPositions[i];
        const effectMid = scrollPositions[i] + 100;
        const effectEnd = scrollPositions[i] + 200;

        if (scrollY < effectMid) {
          let t = (scrollY - effectStart) / (effectMid - effectStart);
          sequentialTextSprite.scale.y = THREE.MathUtils.clamp(t, 0, 1);
        } else if (scrollY < effectEnd) {
          let t = 1 - (scrollY - effectMid) / (effectEnd - effectMid);
          sequentialTextSprite.scale.y = THREE.MathUtils.clamp(t, 0, 1);
        } else {
          sequentialTextSprite.scale.y = 0;
        }
        break;
      }
    }
  } else {
    sequentialTextSprite.material.opacity = 0;
  }

  // Zoom in effect at end of scene
  if (scrollY >= zoomStart && scrollY <= zoomEnd) {
    const t = (scrollY - zoomStart) / (zoomEnd - zoomStart);
    camera.position.z = THREE.MathUtils.lerp(initialCameraZ, minCameraZ, t);
  } else if (scrollY > zoomEnd) {
    camera.position.z = minCameraZ;
  } else {
    camera.position.z = initialCameraZ;
  }
}

export function animateScene1() {
  const fadeSpeed = 0.01;

  if (fadeInProgress.image && imagePlane.material.opacity < 1) {
    imagePlane.material.opacity += fadeSpeed;
    if (imagePlane.material.opacity >= 1) {
      fadeInProgress.image = false;
      assetsLoaded.text1 = true;
      fadeInProgress.text1 = true;
    }
  } else if (fadeInProgress.text1 && textSprite1.material.opacity < 1) {
    textSprite1.material.opacity += fadeSpeed;
    if (textSprite1.material.opacity >= 1) {
      fadeInProgress.text1 = false;
      assetsLoaded.text2 = true;
      fadeInProgress.text2 = true;
    }
  } else if (fadeInProgress.text2 && textSprite2.material.opacity < 1) {
    textSprite2.material.opacity += fadeSpeed;
    if (textSprite2.material.opacity >= 1) {
      fadeInProgress.text2 = false;
    }
  }
}
