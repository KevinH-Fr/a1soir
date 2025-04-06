import * as THREE from 'three';

let imagePlane, textSprite1, textSprite2, sequentialTextSprite;
let assetsLoaded = { image: false, text1: false, text2: false, sequentialText: false };
let fadeInProgress = { image: false, text1: false, text2: false };

const words = ["Robes de mariée", "Costumes", "Robes de soirée", "Ensembles", "Déguisements"];
const scrollPositions = [1000, 1600, 2200, 2800, 3400];

let camera;
let zoomStart = 800;
let zoomEnd = 5000;
const initialCameraZ = 5;
const minCameraZ = 2;

let originalTextScales = {
  text1: new THREE.Vector2(4, 1),
  text2: new THREE.Vector2(3.5, 0.9),
  sequential: new THREE.Vector2(4, 1),
};

export function initScene1() {
  const container = document.getElementById('canvas1');
  const scene = new THREE.Scene();
  camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
  camera.position.z = initialCameraZ;

  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  container.appendChild(renderer.domElement);

  const textureLoader = new THREE.TextureLoader();
  textureLoader.load('images/party.jpg', (texture) => {
    const aspect = texture.image.width / texture.image.height;
    const geometry = new THREE.PlaneGeometry(aspect * 5, 5);
    texture.anisotropy = renderer.capabilities.getMaxAnisotropy();
    const material = new THREE.MeshBasicMaterial({ map: texture, transparent: true, opacity: 0 });
    imagePlane = new THREE.Mesh(geometry, material);
    scene.add(imagePlane);
    assetsLoaded.image = true;
    fadeInProgress.image = true;
  });

  const createTextSprite = (message, fontSize, color, yPosition, targetWidth = 4) => {
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

    const aspect = canvas.width / canvas.height;
    const height = targetWidth / aspect;
    sprite.scale.set(targetWidth, height, 1);
    sprite.position.set(0, yPosition, 0.1);
    return sprite;
  };

  textSprite1 = createTextSprite("AUTOUR D'UN SOIR", 48, 'white', 2, originalTextScales.text1.x);
  textSprite2 = createTextSprite('Mariage et Tenues de soirée', 24, 'white', 1.5, originalTextScales.text2.x);
  sequentialTextSprite = createTextSprite('', 36, 'white', 0, originalTextScales.sequential.x);

  assetsLoaded.sequentialText = true;

  scene.add(textSprite1, textSprite2, sequentialTextSprite);

  window.addEventListener('scroll', () => onScroll(camera));
  return { scene, camera, renderer };
}

function updateTextSprite(sprite, message, targetWidth = 4) {
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

  const aspect = canvas.width / canvas.height;
  const height = targetWidth / aspect;
  sprite.scale.set(targetWidth, height, 1);
}

function onScroll(camera) {
  const scrollY = window.scrollY;

  const fadeStart = 1000;
  const fadeEnd = 2000;
  let opacity = 1;
  if (scrollY >= fadeStart) {
    opacity = 1 - (scrollY - fadeStart) / (fadeEnd - fadeStart);
    opacity = Math.max(0, opacity);
  }

  if (assetsLoaded.text1) textSprite1.material.opacity = opacity;
  if (assetsLoaded.text2) textSprite2.material.opacity = opacity;

  // Keep text visually same size despite zoom
  const zoomFactor = camera.position.z / initialCameraZ;
  textSprite1.scale.set(originalTextScales.text1.x * zoomFactor, originalTextScales.text1.y * zoomFactor, 1);
  textSprite2.scale.set(originalTextScales.text2.x * zoomFactor, originalTextScales.text2.y * zoomFactor, 1);

  if (scrollY > fadeEnd) {
    sequentialTextSprite.material.opacity = 1;

    for (let i = 0; i < scrollPositions.length; i++) {
      if (scrollY >= scrollPositions[i] && (i === scrollPositions.length - 1 || scrollY < scrollPositions[i + 1])) {
        updateTextSprite(sequentialTextSprite, words[i], originalTextScales.sequential.x);

        const effectStart = scrollPositions[i];
        const effectMid = scrollPositions[i] + 200;
        const effectEnd = scrollPositions[i] + 400;

        let scaleY = originalTextScales.sequential.y;
        if (scrollY < effectMid) {
          let t = (scrollY - effectStart) / (effectMid - effectStart);
          scaleY = originalTextScales.sequential.y * THREE.MathUtils.clamp(t, 0, 1);
        } else if (scrollY < effectEnd) {
          let t = 1 - (scrollY - effectMid) / (effectEnd - effectMid);
          scaleY = originalTextScales.sequential.y * THREE.MathUtils.clamp(t, 0, 1);
        } else {
          scaleY = 0;
        }

        // Maintain size despite zoom
        const adjustedX = originalTextScales.sequential.x * zoomFactor;
        const adjustedY = scaleY * zoomFactor;
        sequentialTextSprite.scale.set(adjustedX, adjustedY, 1);
        break;
      }
    }
  } else {
    sequentialTextSprite.material.opacity = 0;
  }

  // Camera zoom
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
