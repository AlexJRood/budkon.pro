// Minimal 360° equirectangular panorama viewer — standalone from scene.js /
// room_scene_provider.dart. Reuses only the WebView+three.js plumbing
// pattern (Flutter<->JS bridge, bundled three.js) established by scene.js;
// it does NOT reuse RoomScene/furniture-editing state, which has no notion
// of a background sphere/skybox to piggyback on.
//
// Bridge protocol (mirrors scene.js's envelope shape):
//   Flutter -> JS: window.onFlutterMessage({type: 'loadPanorama', payload: {url}})
//   JS -> Flutter: callHandler('panoramaBridge', {type: 'ready'|'error', payload})
import * as THREE from './three.module.min.js';
import { OrbitControls } from './OrbitControls.js';

let scene, camera, renderer, controls, sphere;
let ready = false;

function post(type, payload) {
  // flutter_inappwebview, not webview_flutter — see panorama_3d_webview.dart.
  if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
    window.flutter_inappwebview.callHandler('panoramaBridge', { type, payload: payload || {} });
  }
}

function initThree() {
  const canvasHost = document.getElementById('viewport');

  scene = new THREE.Scene();

  camera = new THREE.PerspectiveCamera(
    75,
    window.innerWidth / window.innerHeight,
    0.1,
    1000,
  );
  camera.position.set(0, 0, 0.01);

  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.setSize(window.innerWidth, window.innerHeight);
  canvasHost.appendChild(renderer.domElement);

  // Standing at the center of an inverted sphere: geometry faces point
  // inward (scale.x = -1) so the equirectangular texture wraps around the
  // viewer instead of being seen from outside. Drag direction is inverted
  // to compensate (rotateSpeed negative).
  const geometry = new THREE.SphereGeometry(500, 60, 40);
  geometry.scale(-1, 1, 1);
  const material = new THREE.MeshBasicMaterial({ color: 0x1a1a1f });
  sphere = new THREE.Mesh(geometry, material);
  scene.add(sphere);

  controls = new OrbitControls(camera, renderer.domElement);
  controls.target.set(-0.01, 0, 0);
  controls.enableDamping = true;
  controls.dampingFactor = 0.08;
  controls.enablePan = false;
  controls.enableZoom = false; // dolly-zoom is meaningless standing at the center of the sphere
  controls.rotateSpeed = -0.35;

  // Pinch/wheel "zoom" for a panorama is a FOV change, not a dolly move —
  // OrbitControls has no built-in FOV zoom, so it's handled manually here.
  renderer.domElement.addEventListener('wheel', onWheelZoom, { passive: false });

  window.addEventListener('resize', onResize);

  animate();

  ready = true;
  post('ready', {});
}

function onWheelZoom(event) {
  event.preventDefault();
  const nextFov = camera.fov + Math.sign(event.deltaY) * 3;
  camera.fov = Math.min(90, Math.max(30, nextFov));
  camera.updateProjectionMatrix();
}

function onResize() {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
}

function animate() {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
}

function loadPanorama(url) {
  if (!url) return;

  const loader = new THREE.TextureLoader();
  loader.setCrossOrigin('anonymous');
  loader.load(
    url,
    (texture) => {
      texture.colorSpace = THREE.SRGBColorSpace;
      sphere.material.map = texture;
      sphere.material.color.set(0xffffff);
      sphere.material.needsUpdate = true;
      post('loaded', { url });
    },
    undefined,
    (err) => {
      post('error', { url, message: String(err && err.message ? err.message : err) });
    },
  );
}

window.onFlutterMessage = function onFlutterMessage(envelope) {
  const { type, payload } = envelope || {};
  if (type === 'loadPanorama') {
    loadPanorama(payload && payload.url);
  }
};

initThree();
