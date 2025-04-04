import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';

document.addEventListener("turbo:load", () => {
  const container = document.getElementById("three-canvas");
  const nextContainer = document.getElementById("next-canvas");

  if (!container || container.dataset.initialized === "true") return;
  container.dataset.initialized = "true";

  // === Scene Setup ===
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(75, container.clientWidth / container.clientHeight, 0.1, 1000);
  camera.position.z = 5;

  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setSize(container.clientWidth, container.clientHeight);
  container.appendChild(renderer.domElement);

  // === Create Text Sprite ===
  const createTextSprite = (message, font = 'bold 100px sans-serif', color = 'black') => {
    const canvas = document.createElement('canvas');
    canvas.width = 1024;
    canvas.height = 256;
    const context = canvas.getContext('2d');
    context.clearRect(0, 0, canvas.width, canvas.height);
    context.font = font;
    context.fillStyle = color;
    context.textAlign = 'center';
    context.textBaseline = 'middle';
    context.fillText(message, canvas.width / 2, canvas.height / 2);
    const texture = new THREE.CanvasTexture(canvas);
    texture.minFilter = THREE.LinearFilter;
    texture.needsUpdate = true;
    const material = new THREE.SpriteMaterial({ map: texture, transparent: true, opacity: 0 });
    const sprite = new THREE.Sprite(material);
    sprite.scale.set(0.1, 0.025, 0.025);
    return sprite;
  };

  const updateTextColor = (sprite, message, font, color) => {
    const canvas = sprite.material.map.image;
    const context = canvas.getContext('2d');
    context.clearRect(0, 0, canvas.width, canvas.height);
    context.font = font;
    context.fillStyle = color;
    context.textAlign = 'center';
    context.textBaseline = 'middle';
    context.fillText(message, canvas.width / 2, canvas.height / 2);
    sprite.material.map.needsUpdate = true;
  };

  const interpolateColor = (t) => {
    const r = Math.floor(255 * t);
    return `rgb(${r},0,0)`;
  };

  const textSprite1 = createTextSprite("AUTOUR D'UN SOIR", 'bold 100px sans-serif');
  textSprite1.position.y = 2;
  const textSprite2 = createTextSprite("Mariage et Tenues de soirée", 'normal 60px serif');
  textSprite2.position.y = 1.2;
  scene.add(textSprite1);
  scene.add(textSprite2);

  // === Image Plane Setup ===
  const textureLoader = new THREE.TextureLoader();
  const imageTexture = textureLoader.load('/images/party.jpg');
  const imageMaterial = new THREE.MeshBasicMaterial({ map: imageTexture, transparent: true, opacity: 0 });
  const imageGeometry = new THREE.PlaneGeometry(4, 2.5);
  const imagePlane = new THREE.Mesh(imageGeometry, imageMaterial);
  imagePlane.visible = false;
  scene.add(imagePlane);

  // === Load Model ===
  let model = null;
  let modelMaterials = [];

  const loader = new GLTFLoader();
  loader.load('/models/dress.glb', (gltf) => {
    model = gltf.scene;
    model.scale.set(3, 3, 3);
    model.position.y = -4;
    model.traverse((child) => {
      if (child.isMesh) {
        child.material.transparent = true;
        child.material.opacity = 0;
        modelMaterials.push(child.material);
      }
    });
    scene.add(model);
  });

  // === Second Scene Setup ===
  const scene2 = new THREE.Scene();
  const camera2 = new THREE.PerspectiveCamera(75, nextContainer.clientWidth / nextContainer.clientHeight, 0.1, 1000);
  camera2.position.z = 5;

  const renderer2 = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer2.setSize(nextContainer.clientWidth, nextContainer.clientHeight);
  nextContainer.appendChild(renderer2.domElement);

  const torus = new THREE.Mesh(new THREE.TorusGeometry(1, 0.4, 16, 100), new THREE.MeshStandardMaterial({ color: 0x8e44ad }));
  scene2.add(torus);
  scene2.add(new THREE.PointLight(0xffffff, 1).position.set(5, 5, 5));

  function animateSecondScene() {
    requestAnimationFrame(animateSecondScene);
    torus.rotation.x += 0.01;
    torus.rotation.y += 0.01;
    renderer2.render(scene2, camera2);
  }
  animateSecondScene();

  window.addEventListener('resize', () => {
    camera.aspect = container.clientWidth / container.clientHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(container.clientWidth, container.clientHeight);
    camera2.aspect = nextContainer.clientWidth / nextContainer.clientHeight;
    camera2.updateProjectionMatrix();
    renderer2.setSize(nextContainer.clientWidth, nextContainer.clientHeight);
  });

  // === Animation State ===
  let frame = 0;
  let lastTextColor1 = '';
  let lastTextColor2 = '';
  let lastLoggedScroll = 0;

  const zoomDuration = 60;
  const secondTextDelay = 30;
  const secondTextFadeDuration = 20;

  // === Scroll + Frame Thresholds ===
  const textAnimationEndFrame = 120;
  const imageScrollStart = 100;
  const imageScrollEnd = 800;
  const modelScrollStart = 800;
  const modelScrollEnd = 1400;
  const colorChangeStart = 800;
  const colorChangeEnd = 3000;
  const sceneSwitchThreshold = 4000;

  function animate() {
    requestAnimationFrame(animate);
    const scrollY = window.scrollY;

    if (frame % 10 === 0 && scrollY !== lastLoggedScroll) {
      console.log("ScrollY:", scrollY);
      lastLoggedScroll = scrollY;
    }

    // === Initial Text Zoom ===
    if (frame < zoomDuration) {
      const t = frame / zoomDuration;
      const scale = THREE.MathUtils.lerp(0.1, 8, t);
      textSprite1.scale.set(scale, scale * 0.25, 1);
      textSprite1.material.opacity = 1;
    }

    if (frame >= zoomDuration + secondTextDelay) {
      const t = Math.min((frame - zoomDuration - secondTextDelay) / secondTextFadeDuration, 1);
      textSprite2.material.opacity = t;
      textSprite2.scale.set(6, 1.5, 1);
    }

    // === Show image after text animation ends ===
    if (frame >= textAnimationEndFrame && scrollY < imageScrollStart) {
      imagePlane.visible = true;
      imagePlane.scale.set(1, 0.625, 1);
      imageMaterial.opacity = 1;
    }

    // === Image zoom on scroll ===
    if (scrollY >= imageScrollStart && scrollY <= imageScrollEnd) {
      const t = (scrollY - imageScrollStart) / (imageScrollEnd - imageScrollStart);
      const zoomScale = THREE.MathUtils.lerp(1, 3, t);
      imagePlane.visible = true;
      imagePlane.scale.set(zoomScale, zoomScale * 0.625, 1);
      imageMaterial.opacity = 1 - t; // fade during zoom
    } else if (scrollY > imageScrollEnd) {
      imagePlane.visible = false;
      imageMaterial.opacity = 0;
    }

    // === Model Fade-In after image zoom ===
    if (model && modelMaterials.length > 0) {
        if (scrollY < modelScrollStart) {
          model.visible = false;
          modelMaterials.forEach(mat => mat.opacity = 0);
        } else if (scrollY >= modelScrollStart && scrollY <= modelScrollEnd) {
          const t = (scrollY - modelScrollStart) / (modelScrollEnd - modelScrollStart);
          model.visible = true;
          modelMaterials.forEach(mat => mat.opacity = t);
        } else {
          model.visible = true;
          modelMaterials.forEach(mat => mat.opacity = 1);
        }
      }
      

    // === Text Color Interpolation ===
    const baseFont = Math.round(container.clientWidth / 10);
    const font1 = `bold ${baseFont}px sans-serif`;
    const font2 = `normal ${Math.round(baseFont * 0.8)}px serif`;

    const colorT = Math.min(Math.max((scrollY - colorChangeStart) / (colorChangeEnd - colorChangeStart), 0), 1);
    const interpolatedColor = interpolateColor(colorT);
    if (interpolatedColor !== lastTextColor1) {
      updateTextColor(textSprite1, "AUTOUR D'UN SOIR", font1, interpolatedColor);
      lastTextColor1 = interpolatedColor;
    }
    if (interpolatedColor !== lastTextColor2) {
      updateTextColor(textSprite2, "Mariage et Tenues de soirée", font2, interpolatedColor);
      lastTextColor2 = interpolatedColor;
    }

    // === Rotate Model ===
    const baseRotationSpeed = 0.0025;
    const scrollRotationBoost = scrollY * 0.0001;
    if (model) model.rotation.y += baseRotationSpeed + scrollRotationBoost;

    renderer.render(scene, camera);
    frame++;

    // === Scene Switch ===
    container.style.opacity = scrollY > sceneSwitchThreshold ? '0' : '1';
    nextContainer.style.opacity = scrollY > sceneSwitchThreshold ? '1' : '0';
  }

  animate();
});
