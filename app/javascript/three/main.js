import { initScene1, animateScene1 } from './scene1.js';
import { initScene2, animateScene2 } from './scene2.js';
import { initScene3, animateScene3 } from './scene3.js';
import { initScene4, animateScene4 } from './scene4.js';

const scenes = [
  { init: initScene1, animate: animateScene1, canvasId: 'canvas1' },
  { init: initScene2, animate: animateScene2, canvasId: 'canvas2' },
  { init: initScene3, animate: animateScene3, canvasId: 'canvas3' },
  { init: initScene4, animate: animateScene4, canvasId: 'canvas4' }
];

const initializedScenes = scenes.map(({ init, animate, canvasId }) => {
  const { scene, camera, renderer } = init();
  return { scene, camera, renderer, animate, canvasId };
});

function animate() {
  requestAnimationFrame(animate);

  
  const scrollY = window.scrollY;
  document.getElementById('scrollPosition').textContent = `Scroll Y: ${scrollY.toFixed(0)}px`;
  const windowHeight = window.innerHeight;
  const sceneHeight = 5000; // Each scene spans 2000px of scroll
  const transitionZone = 500; // Pixels over which the fade transition occurs

  initializedScenes.forEach(({ scene, camera, renderer, animate, canvasId }, index) => {
    const canvasElement = document.getElementById(canvasId);
    const sceneStart = index * sceneHeight;
    const sceneEnd = sceneStart + sceneHeight;

    if (scrollY >= sceneStart && scrollY < sceneEnd) {
      // Scene is within its scroll range
      const transitionStart = sceneEnd - transitionZone;
      if (scrollY >= transitionStart) {
        // Within the transition zone, calculate fade-out opacity
        const progress = (scrollY - transitionStart) / transitionZone;
        canvasElement.style.opacity = 1 - progress;
      } else {
        // Fully visible
        canvasElement.style.opacity = 1;
      }

      animate(scene);
      renderer.render(scene, camera);
    } else {
      // Scene is outside its scroll range
      canvasElement.style.opacity = 0;
    }
  });
}

animate();

window.addEventListener('resize', () => {
  initializedScenes.forEach(({ camera, renderer }) => {
    const { innerWidth, innerHeight } = window;
    camera.aspect = innerWidth / innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(innerWidth, innerHeight);
  });
});
