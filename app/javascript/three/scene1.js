import * as THREE from 'three';

let camera, renderer, scene;

const initialCameraZ = 5;

const allImages = [
  {
    path: 'images/image1.png',
    scrollStart: 0,
    scrollEnd: 1500,
    text: "Mariage et Tenues de soirée \nVente - Location",
    labelColor: "#1e2120",
    fontSize: 128,
    zoomTarget: { x: -1.9, y: -1, z: 1 },
    isLarge: true
  },
  {
    path: 'images/image2.png',
    scrollStart: 1500,
    scrollEnd: 3000,
    text: "Robes de mariée et de soirée",
    labelColor: "#1e2120",
    fontSize: 128,
    zoomTarget: { x: 3.5, y: 2, z: 0.8 }
  },
  {
    path: 'images/image3.png',
    scrollStart: 3000,
    scrollEnd: 4500,
    text: "Costumes et déguisements",
    labelColor: "#1e2120",
    fontSize: 128,
    zoomTarget: { x: -1, y: -1, z: 1.2 }
  }
];

export function initScene1() {
  const container = document.getElementById('canvas1');
  scene = new THREE.Scene();

  camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
  camera.position.set(0, 0, initialCameraZ);

  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  container.appendChild(renderer.domElement);

  const textureLoader = new THREE.TextureLoader();

  allImages.forEach((img, index) => {
    textureLoader.load(img.path, (texture) => {
      const screenHeight = 2 * Math.tan((camera.fov * Math.PI) / 360) * camera.position.z;
      const screenWidth = screenHeight * camera.aspect;
      const imgAspect = texture.image.width / texture.image.height;
      const screenAspect = screenWidth / screenHeight;

      let planeWidth, planeHeight;
      if (imgAspect > screenAspect) {
        planeHeight = screenHeight;
        planeWidth = screenHeight * imgAspect;
      } else {
        planeWidth = screenWidth;
        planeHeight = screenWidth / imgAspect;
      }

      const geometry = new THREE.PlaneGeometry(planeWidth, planeHeight);
      const material = new THREE.MeshBasicMaterial({
        map: texture,
        transparent: true,
        opacity: index === 0 ? 1 : 0
      });

      const mesh = new THREE.Mesh(geometry, material);
      mesh.position.z = 0;

      const textSprite = createAnimatedTextSprite(
        img.text,
        img.labelColor || "#ffffff",
        img.isLarge,
        img.fontSize
      );
      textSprite.position.set(1, -planeHeight / 2 + 1, 0.1);
      textSprite.material.opacity = index === 0 ? 1 : 0;

      Object.assign(img, { mesh, material, textSprite });
      scene.add(mesh);
      scene.add(textSprite);
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

function createAnimatedTextSprite(fullText, color = "#ffffff", isLarge = false, fontSizeOverride = null) {
  const canvas = document.createElement('canvas');
  const context = canvas.getContext('2d');

  const fontSize = fontSizeOverride || (isLarge ? 128 : 64);
  const fontFamily = isLarge ? "'Dancing Script', cursive" : "'Brush Script MT', cursive";

  context.font = `${fontSize}px ${fontFamily}`;
  const textWidth = Math.max(...fullText.split('\n').map(line => context.measureText(line).width));
  canvas.width = textWidth;
  canvas.height = fontSize * 3;

  const texture = new THREE.CanvasTexture(canvas);
  const material = new THREE.SpriteMaterial({ map: texture, transparent: true });
  const sprite = new THREE.Sprite(material);
  const scale = 0.01 * fontSize;
  sprite.scale.set((canvas.width / canvas.height) * scale, scale, 1);

  sprite.userData = { fullText, color, fontSize, fontFamily, canvas, context, texture };
  return sprite;
}

function updateTextReveal(sprite, progress) {
  if (!sprite || !sprite.userData) return;
  const { fullText, color, fontSize, fontFamily, canvas, context, texture } = sprite.userData;

  const lines = fullText.split('\n');
  const totalLength = lines.join('').length;
  const visibleChars = Math.floor(totalLength * progress);

  let charsRemaining = visibleChars;
  context.clearRect(0, 0, canvas.width, canvas.height);
  context.font = `${fontSize}px ${fontFamily}`;
  context.fillStyle = color;
  context.textBaseline = 'top';

  let yOffset = 0;
  for (let line of lines) {
    let lineText = '';
    if (charsRemaining >= line.length) {
      lineText = line;
      charsRemaining -= line.length;
    } else if (charsRemaining > 0) {
      lineText = line.slice(0, charsRemaining);
      charsRemaining = 0;
    }
    context.fillText(lineText + (charsRemaining === 0 ? '|' : ''), 0, yOffset);
    yOffset += fontSize * 1.2;
  }

  texture.needsUpdate = true;
}

function onScroll() {
  const scrollY = window.scrollY;
  let cameraSet = false;

  allImages.forEach((img, index) => {
    const { scrollStart, scrollEnd, material, textSprite, zoomTarget } = img;
    const fadeRange = 300;
    const textEnd = scrollStart + (scrollEnd - scrollStart) * 0.6;
    const zoomStart = textEnd;

    if (!material || !textSprite) return;

    let fadeInT = 1;
    let fadeOutT = 1;

    if (index === 0) {
      // For image1: no fade in, only fade out
      if (scrollY > scrollEnd - fadeRange) {
        fadeOutT = (scrollEnd - scrollY) / fadeRange;
      }
      fadeInT = 1; // always fully visible on enter
    } else {
      // Other images: fade in and out normally
      if (scrollY < scrollStart + fadeRange) {
        fadeInT = (scrollY - scrollStart) / fadeRange;
      }
      if (scrollY > scrollEnd - fadeRange) {
        fadeOutT = (scrollEnd - scrollY) / fadeRange;
      }
    }

    const finalOpacity = Math.max(0, Math.min(fadeInT, fadeOutT));
    material.opacity = finalOpacity;
    textSprite.material.opacity = finalOpacity;

    if (scrollY < scrollStart || scrollY > scrollEnd) {
      updateTextReveal(textSprite, 0);
      return;
    }

    if (scrollY <= textEnd) {
      const textProgress = (scrollY - scrollStart) / (textEnd - scrollStart);
      updateTextReveal(textSprite, Math.max(0, Math.min(1, textProgress)));
      if (!cameraSet) {
        camera.position.set(0, 0, initialCameraZ);
        cameraSet = true;
      }
    } else {
      updateTextReveal(textSprite, 1);
      const t = (scrollY - zoomStart) / (scrollEnd - zoomStart);
      if (!cameraSet) {
        camera.position.set(
          THREE.MathUtils.lerp(0, zoomTarget.x, t),
          THREE.MathUtils.lerp(0, zoomTarget.y, t),
          THREE.MathUtils.lerp(initialCameraZ, zoomTarget.z, t)
        );
        cameraSet = true;
      }
    }
  });
}

