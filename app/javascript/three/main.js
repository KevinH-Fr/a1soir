import { initScene1 } from './scene1.js';
import { initScene2 } from './scene2.js';
import { initSceneOverlay, animateSceneOverlay } from './sceneOverlay.js';

// Define each main scene and its scroll height
const scenes = [
  { init: initScene1, canvasId: 'canvas1', scrollHeight: 5000 },
  { init: initScene2, canvasId: 'canvas2', scrollHeight: 5000 }
];

// Calculate scroll offset for each scene
const sceneOffsets = [];
let cumulativeHeight = 0;
scenes.forEach(({ scrollHeight }) => {
  sceneOffsets.push(cumulativeHeight);
  cumulativeHeight += scrollHeight;
});

// Initialize main scenes
const initializedScenes = scenes.map(({ init, canvasId }) => {
  const { scene, camera, renderer } = init();
  return { scene, camera, renderer, canvasId };
});

// Initialize overlay scene
const { scene: overlayScene, camera: overlayCamera, renderer: overlayRenderer } = initSceneOverlay();

// Main animation loop
function animate() {
  requestAnimationFrame(animate);

  const scrollY = window.scrollY;
  const transitionZone = 500;

  // Optional scroll position display
  const scrollIndicator = document.getElementById('scrollPosition');
  if (scrollIndicator) {
    scrollIndicator.textContent = `Scroll Y: ${scrollY.toFixed(0)}px`;
  }

  // Handle rendering for each main scene
  initializedScenes.forEach(({ scene, camera, renderer, canvasId }, index) => {
    const canvasElement = document.getElementById(canvasId);
    const sceneStart = sceneOffsets[index];
    const sceneEnd = sceneStart + scenes[index].scrollHeight;

    if (scrollY >= sceneStart && scrollY < sceneEnd) {
      const transitionStart = sceneEnd - transitionZone;

      if (scrollY >= transitionStart) {
        const progress = (scrollY - transitionStart) / transitionZone;
        canvasElement.style.opacity = 1 - progress;
      } else {
        canvasElement.style.opacity = 1;
      }

      renderer.render(scene, camera);
    } else {
      canvasElement.style.opacity = 0;
    }
  });

  // Always render overlay model scene
  animateSceneOverlay();
}

// Start animation loop
animate();

// Resize handling
window.addEventListener('resize', () => {
  initializedScenes.forEach(({ camera, renderer }) => {
    const { innerWidth, innerHeight } = window;
    camera.aspect = innerWidth / innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(innerWidth, innerHeight);
  });

  overlayCamera.aspect = window.innerWidth / window.innerHeight;
  overlayCamera.updateProjectionMatrix();
  overlayRenderer.setSize(window.innerWidth, window.innerHeight);
});
