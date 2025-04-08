import { initScene1 } from './scene1.js';
import { initScene2 } from './scene2.js';

// Define each scene and its scroll height
const scenes = [
  { init: initScene1, canvasId: 'canvas1', scrollHeight: 5000 },
  { init: initScene2, canvasId: 'canvas2', scrollHeight: 5000 }
];


// Calculate scene start offsets based on scroll height
const sceneOffsets = [];
let cumulativeHeight = 0;
scenes.forEach(({ scrollHeight }) => {
  sceneOffsets.push(cumulativeHeight);
  cumulativeHeight += scrollHeight;
});

// Initialize all scenes
const initializedScenes = scenes.map(({ init, animate, canvasId }) => {
  const { scene, camera, renderer } = init();
  return { scene, camera, renderer, animate, canvasId };
});

// Animate all scenes
function animate() {
  requestAnimationFrame(animate);

  const scrollY = window.scrollY;
  const transitionZone = 500;

  // Optional debug output
  const scrollIndicator = document.getElementById('scrollPosition');
  if (scrollIndicator) {
    scrollIndicator.textContent = `Scroll Y: ${scrollY.toFixed(0)}px`;
  }

  initializedScenes.forEach(({ scene, camera, renderer, animate, canvasId }, index) => {
    const canvasElement = document.getElementById(canvasId);
    const sceneStart = sceneOffsets[index];
    const sceneEnd = sceneStart + scenes[index].scrollHeight;

    if (scrollY >= sceneStart && scrollY < sceneEnd) {
      // Handle fade-out near the end of scene
      const transitionStart = sceneEnd - transitionZone;
      if (scrollY >= transitionStart) {
        const progress = (scrollY - transitionStart) / transitionZone;
        canvasElement.style.opacity = 1 - progress;
      } else {
        canvasElement.style.opacity = 1;
      }

    //  animate(scene);
      renderer.render(scene, camera);
    } else {
      // Scene not in view
      canvasElement.style.opacity = 0;
    }
  });
}

animate();

// Handle resize
window.addEventListener('resize', () => {
  initializedScenes.forEach(({ camera, renderer }) => {
    const { innerWidth, innerHeight } = window;
    camera.aspect = innerWidth / innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(innerWidth, innerHeight);
  });
});
