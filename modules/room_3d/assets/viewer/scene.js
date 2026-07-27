// room_3d viewer — three.js scene driven entirely by the RoomScene JSON
// contract (docs/sims_mode/ARCHITECTURE.md section 3) via the Flutter<->JS
// bridge (section 6). This file owns NO business state — it only renders
// whatever Flutter tells it to via window.onFlutterMessage, and reports
// interaction events back via RoomSceneBridge.postMessage. Flutter
// (room_scene_provider.dart) remains the single source of truth.
import * as THREE from './three.module.min.js';
import { OrbitControls } from './OrbitControls.js';
import { GLTFExporter } from './GLTFExporter.js';
import { GLTFLoader } from './GLTFLoader.js';

const DEFAULT_ITEM_SIZE = { widthM: 0.6, depthM: 0.6, heightM: 0.8 };
const DEFAULT_STAIR_WIDTH_M = 1.0;
const STAIR_STEP_RISE_M = 0.18; // ~real-world comfortable step rise, used only to pick a step count
const STAIR_COLOR = 0x8a7860;
const DEFAULT_STORY_HEIGHT_M = 2.8; // mirrors RoomFloor's kDefaultStoryHeightM in room_scene.dart

let scene, camera, renderer, controls;
let roomGroup; // everything belonging to the current RoomScene, rebuilt on loadScene
let ready = false;
let ambientLight, sunLight, presentationFillLight;
// "Tryb prezentacyjny" (FINAL_VISION.md §7.3) — soft shadows + a warmer fill
// light, toggled on demand since it's markedly more expensive than the flat
// working-mode lighting (a shadow-map render pass every frame). Off by
// default; the working mode stays fast/flat, exactly as documented.
let presentationModeEnabled = false;

let selectedItemId = null;
let selectedWallId = null;
let selectedRoomId = null;
let dragState = null; // {itemId, plane, offset}

// Wall endpoint editing (FINAL_VISION.md §4's "edit an existing wall after
// the fact" debt item) — a selected wall shows two small draggable handle
// spheres at its endpoints. Dragging one is a LIGHTWEIGHT preview only (a
// moved handle + a rubber-band line) — it never touches the wall's real
// segmented geometry mid-drag (openings/corner-fill/cutaway would all need
// re-deriving live, not worth it for a preview). The actual wall only gets
// rebuilt once, on release, via a full floor reload driven by Flutter's
// canonical RoomWall data — see wallEndpointMoved's handling in
// room_scene_actions.dart.
let wallEndpointHandlesGroup = null;
let wallEndpointDragState = null; // {wallId, endpoint: 'start'|'end', previewLine}
const WALL_ENDPOINT_HANDLE_RADIUS_M = 0.11;
const WALL_ENDPOINT_HANDLE_COLOR = 0xffb703;

// Placing a new door/window opening directly on the currently selected wall
// (FINAL_VISION.md §4's last Buduj debt item) — set via the `setPlacingOpening`
// bridge command from a button in WallMaterialPanel (Flutter owns the
// on/off toggle state, this is just the JS-side flag it's driving). The
// NEXT click on the selected wall's own hitbox places the opening there;
// same "commit via a full floor reload" reasoning as wall endpoint editing
// — a new cutout needs the wall's real segmented geometry re-derived,
// which only `loadScene`'s full rebuild already does correctly.
let placingOpeningKind = null; // null | 'door' | 'window'

// True floor stacking (FINAL_VISION.md §6 — user chose real 3D stacking
// over a camera-only fake, scoped to ±1 adjacent floor, dimmed, click to
// switch). The active floor keeps rendering exactly as before (roomGroup at
// y=0, full interactivity, unchanged) — only the floor below/above are new:
// dimmed, non-interactive (except for "click anywhere on them = switch to
// that floor"), positioned at a Y offset Flutter computes from each floor's
// own `storyHeightM` (RoomFloor's per-floor, user-editable field). Rebuilt
// wholesale on every loadScene (they arrive bundled in the same payload as
// the active floor's own data, not a separate async command the way the
// superseded flat ghost-floor trace needed to be).
let adjacentFloorGroups = { below: null, above: null };
const ADJACENT_FLOOR_COLOR = 0x6fa8dc;
const ADJACENT_FLOOR_OPACITY = 0.28;

// Build mode: draw a new wall (2 clicked points -> one wall) or a new
// virtual room polygon (3+ clicked points, committed on an explicit
// "finish" command from Flutter) — see setBuildMode/handleBuildClick.
let buildMode = null; // null | 'wall' | 'room' | 'stair'
let buildIsVirtual = false;
let buildThicknessM = 0.15;
let buildPoints = []; // [{x, z}, ...] in world XZ, already snapped
let buildPreviewGroup = null;

// First-person walkthrough mode ("zwiedzanie") — toggled with F or a toolbar
// button. Replaces OrbitControls entirely while active: WASD/arrow keys move
// the camera along the floor at a fixed eye height, holding the left mouse
// button and dragging looks around (yaw/pitch), same "click-drag to look"
// convention as most first-person tools. Wall collision (below) was
// deliberately deferred until openings became real cutouts (§5) — colliding
// with solid boxes that had no door gaps would've trapped you in whichever
// room you started in. Now that a wall is a Group of segments with real
// gaps (see computeWallSolidRects), collision is implemented as the natural
// follow-up.
let walkModeEnabled = false;
let walkYaw = 0;
let walkPitch = 0;
let walkLooking = false; // true while the look-drag button is held
const walkKeysPressed = new Set();
const WALK_SPEED_MPS = 2.2;
const WALK_EYE_HEIGHT_M = 1.6;
const WALK_LOOK_SENSITIVITY = 0.0025;
// Treated as a vertical cylinder from the floor up to this height when
// testing wall collision — NOT literally "collide only at eye height".
// A window's sill segment (e.g. y:0-0.9) must still block even though the
// eye (1.6m) sits above it; using "does any solid rect start below this
// height" instead of "is eye height inside a solid rect" gets that right:
// a full door gap (sill 0, no below-sill rect at all) has nothing under
// this threshold and is walkable, while a window's below-sill rect starts
// at 0 < 1.8 and blocks, and its above-lintel rect (well above head height)
// correctly doesn't.
const WALK_BODY_TOP_M = 1.8;
// Treated as a circle around the camera for collision — keeps the player
// from clipping into a wall corner-on even though the collision test itself
// is a point-vs-rect check against the wall's centerline.
const WALK_PLAYER_RADIUS_M = 0.3;
const WALK_MOVE_KEYS = new Set([
  'w', 'a', 's', 'd', 'arrowup', 'arrowdown', 'arrowleft', 'arrowright',
]);
let lastAnimateTimeMs = null;

// Smooth camera transitions (FINAL_VISION.md §2.2) — every orbit-camera
// "jump" (camera presets, minimap teleport, axis-gizmo snap) used to be an
// instant `camera.position.set` with no interpolation anywhere in this
// codebase; this is the one shared tween used by all three instead of each
// hand-rolling its own. Deliberately NOT used for walk-mode entry/exit
// (those intentionally preserve the exact look direction the user was
// already facing) or for anything per-frame like drag/cutaway.
let cameraTransition = null; // {fromPos, toPos, fromTarget, toTarget, elapsed}
const CAMERA_TRANSITION_DURATION_S = 0.4;

// Saved camera views ("zakładki kamery") — see onKeyDown's Ctrl+1..9/1..9
// handling. Slot key -> {position: Vector3, target: Vector3}.
const savedCameraViews = new Map();

function easeInOutCubic(t) {
  return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
}

function animateCameraTo(toPosition, toTarget) {
  cameraTransition = {
    fromPos: camera.position.clone(),
    toPos: toPosition.clone(),
    fromTarget: controls.target.clone(),
    toTarget: toTarget.clone(),
    elapsed: 0,
  };
}

// Returns true if a transition is in progress (and already called
// controls.update() itself) so animate() knows to skip its own normal
// controls.update() call for this frame.
function updateCameraTransition(deltaSeconds) {
  if (!cameraTransition) return false;

  cameraTransition.elapsed += deltaSeconds;
  const t = Math.min(cameraTransition.elapsed / CAMERA_TRANSITION_DURATION_S, 1);
  const eased = easeInOutCubic(t);

  camera.position.lerpVectors(cameraTransition.fromPos, cameraTransition.toPos, eased);
  controls.target.lerpVectors(cameraTransition.fromTarget, cameraTransition.toTarget, eased);
  controls.update();

  if (t >= 1) cameraTransition = null;
  return true;
}

// Per-wall length labels ("Wymiary", §7.1's remaining half — a permanent
// technical-drawing overlay, distinct from the on-demand Miarka tool).
// Toggled from the toolbar only, no hotkey (unlike cutaway/walk/measure —
// nothing else needs to auto-exit or cross-cancel with it, it's purely a
// display overlay with no interaction of its own).
let dimensionsEnabled = false;
const dimensionLabelDivsByWallId = new Map();
const DIMENSION_LABEL_HEIGHT_OFFSET_M = 0.3; // above the wall's own height

// Measuring tool ("Miarka") — toggled with M or a toolbar button. Click a
// first point, click a second, see the distance as a screen-space label
// (#measure-label in index.html — three.js needs a vendored font for real
// 3D text, a plain HTML overlay projected each frame is the standard
// lighter-weight alternative). Purely a viewport reference tool — never
// touches RoomScene, nothing to persist or undo. Snaps to the same existing
// wall corners/centerlines as Buduj (reuses snapBuildPoint) so you can
// measure corner-to-corner precisely, not eyeball it.
let measureModeEnabled = false;
let measureStart = null; // {x, z} once the first point is placed, else null
let measureLiveEnd = null; // live (rubber-band) second point, while mid-measurement
let measureCompleted = null; // {start, end} of the last finished measurement
let measurePreviewGroup = null;
const MEASURE_MODE_TOGGLE_KEY = 'm';
const MEASURE_LINE_COLOR = 0xffd166;

// Minimap: a second, orthographic, top-down camera rendering the SAME scene
// into a small scissored rect of the same canvas each frame (see
// renderMinimap) — deliberately not a render-to-texture-then-draw-a-quad
// setup or a second <canvas>/WebGL context, since restricting the existing
// renderer's viewport/scissor for a second render() call is the standard,
// much simpler technique for a picture-in-picture view. The camera-position
// indicator (a small triangle) lives on its own three.js Layer so it's
// visible in the minimap render but invisible in the main one, without
// needing a second copy of the scene graph.
let minimapCamera = null;
let minimapIndicator = null;
let minimapCenterX = 0;
let minimapCenterZ = 0;
let minimapHalfExtent = 5;
const MINIMAP_LAYER = 1;
const MINIMAP_SIZE_PX = 180;
const MINIMAP_MARGIN_PX = 16;
const MINIMAP_PADDING_M = 1.5;

// CAD-style axis orientation gizmo, top-right corner (opposite the
// minimap) — user-requested "something axis-like, so orbiting is easy,
// like in CAD". A small, fully separate scene (not the room scene, no
// layers needed) rendered with the same second-camera-into-a-scissored-
// rect technique as the minimap, just mirroring the MAIN camera's
// rotation instead of a fixed top-down view. Clicking one of the 6
// axis-end spheres snaps the main camera to look straight down that axis
// — the actual "easy to orbit"/reorient payoff, not just a passive
// indicator.
let axisGizmoScene = null;
let axisGizmoCamera = null;
const AXIS_GIZMO_SIZE_PX = 96;
const AXIS_GIZMO_MARGIN_PX = 16;
const AXIS_GIZMO_DISTANCE = 4; // gizmo camera's distance from its own scene origin
const AXIS_GIZMO_ARM_LENGTH = 1;
const AXIS_GIZMO_SPHERE_RADIUS = 0.22;

const itemMeshesById = new Map();
const wallZoneMeshesByZoneId = new Map();
const wallDefaultMaterialMeshesByWallId = new Map();
const floorMeshesByRoomId = new Map();

// Invisible, always-full-height proxy per wall, used only for click
// hit-testing — deliberately decoupled from the visible wall mesh, which
// the cutaway system shrinks/grows over time and whose outward-normal
// heuristic can misjudge an interior partition wall or a wall of a concave
// (L-shaped) room. Without this, a wall that's currently shrunk to its
// skirting-board stub (or wrongly judged "in the way" from inside such a
// room) becomes impossible to click at head height — see
// docs/sims_mode/IMPLEMENTATION_CHECKLIST.md.
const wallHitboxMeshesByWallId = new Map();

// Rooms can overlap in plan (a virtual room polygon sits inside its parent
// room, see addRoom) — each floor mesh gets a tiny, increasing Y offset by
// build order so a later-added (typically the virtual/overlay) floor
// consistently renders on top instead of z-fighting with the one below it.
let floorLayerCounter = 0;

// 2D (XZ) centerline + half-thickness (+ cached outward normal once
// computed) per wall — used by the cutaway system and furniture wall-snap.
const wallSegmentsById = new Map();

function post(type, payload) {
  // flutter_inappwebview, not webview_flutter's JavaScriptChannel — see
  // room_3d_webview.dart for why (no Windows/Linux desktop support in
  // webview_flutter). callHandler auto-serializes the argument, no need to
  // JSON.stringify manually.
  if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
    window.flutter_inappwebview.callHandler('roomSceneBridge', { type, payload: payload || {} });
  }
}

function initThree() {
  const canvasHost = document.getElementById('viewport');

  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x1a1a1f);

  camera = new THREE.PerspectiveCamera(
    55,
    window.innerWidth / window.innerHeight,
    0.05,
    500,
  );
  camera.position.set(6, 5, 6); // matches setCameraPreset('orbit')'s target — controls don't exist yet

  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.setSize(window.innerWidth, window.innerHeight);
  canvasHost.appendChild(renderer.domElement);

  ambientLight = new THREE.AmbientLight(0xffffff, 0.65);
  scene.add(ambientLight);

  sunLight = new THREE.DirectionalLight(0xffffff, 0.9);
  sunLight.position.set(5, 8, 4);
  scene.add(sunLight);
  // Shadow-camera frustum sized for a typical few-room scene (a handful of
  // meters across) — configured once here rather than fit to the actual
  // wall bounding box like the minimap's orthographic camera, since redoing
  // this per-scene would need re-baking the shadow map anyway; a fixed,
  // generous frustum is the simpler tradeoff for a toggle that's already
  // off by default in the common case.
  sunLight.shadow.mapSize.set(2048, 2048);
  sunLight.shadow.camera.near = 1;
  sunLight.shadow.camera.far = 40;
  sunLight.shadow.camera.left = -15;
  sunLight.shadow.camera.right = 15;
  sunLight.shadow.camera.top = 15;
  sunLight.shadow.camera.bottom = -15;
  sunLight.shadow.bias = -0.0015;

  // Warm sky / cool ground fill light — intensity 0 until presentation mode
  // is enabled (setPresentationModeEnabled), kept as a real light object
  // from the start rather than lazily created so toggling never has to
  // handle "does it exist yet."
  presentationFillLight = new THREE.HemisphereLight(0xfff2e0, 0x30302a, 0);
  scene.add(presentationFillLight);

  controls = new OrbitControls(camera, renderer.domElement);
  controls.target.set(0, 1, 0);
  controls.enableDamping = true;
  controls.dampingFactor = 0.08;
  controls.maxPolarAngle = Math.PI * 0.49; // don't let the camera dip below the floor
  // Right-click already pans by OrbitControls' default; middle-click (mouse
  // wheel button) drag now does too, instead of the default dolly-by-drag
  // (redundant with the scroll wheel, which zooms regardless of this map).
  controls.mouseButtons = {
    LEFT: THREE.MOUSE.ROTATE,
    MIDDLE: THREE.MOUSE.PAN,
    RIGHT: THREE.MOUSE.PAN,
  };

  roomGroup = new THREE.Group();
  scene.add(roomGroup);

  // Lives outside roomGroup so a mid-draw click/wall/room in progress
  // survives incremental commands (addWall/addRoom don't touch it) and is
  // only ever cleared by build-mode transitions themselves, not loadScene's
  // full rebuild — see clearRoomGroup, which still resets build state since
  // a brand new scene invalidates any in-progress snap targets.
  buildPreviewGroup = new THREE.Group();
  scene.add(buildPreviewGroup);

  measurePreviewGroup = new THREE.Group();
  scene.add(measurePreviewGroup);

  // Lives outside roomGroup for the same reason buildPreviewGroup does —
  // survives incremental commands untouched, only rebuilt by selectWall
  // itself (and cleared wholesale by clearRoomGroup on a full scene reload).
  wallEndpointHandlesGroup = new THREE.Group();
  scene.add(wallEndpointHandlesGroup);

  setupMinimap();
  setupAxisGizmo();

  window.addEventListener('resize', onResize);
  window.addEventListener('keydown', onKeyDown);
  window.addEventListener('keydown', onWalkKeyDown);
  window.addEventListener('keyup', onWalkKeyUp);
  renderer.domElement.addEventListener('pointerdown', onPointerDown);
  renderer.domElement.addEventListener('pointermove', onPointerMove);
  renderer.domElement.addEventListener('pointerup', onPointerUp);

  animate();
  ready = true;
  post('ready', {});
}

function onResize() {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
}

function animate(nowMs) {
  requestAnimationFrame(animate);

  const hasValidPrevious = lastAnimateTimeMs !== null && typeof nowMs === 'number';
  const deltaSeconds = hasValidPrevious ? Math.min((nowMs - lastAnimateTimeMs) / 1000, 0.1) : 0;
  lastAnimateTimeMs = typeof nowMs === 'number' ? nowMs : lastAnimateTimeMs;

  if (walkModeEnabled) {
    updateWalkMovement(deltaSeconds);
  } else {
    if (!updateCameraTransition(deltaSeconds)) controls.update();
    updateWallCutaway();
  }
  if (measureModeEnabled) updateMeasureLabelPosition();
  if (dimensionsEnabled) updateDimensionLabels();
  renderer.render(scene, camera);
  renderMinimap();
  renderAxisGizmo();
}

// ---------------------------------------------------------------------------
// Sims-style wall cutaway: walls on the camera-facing side of the room
// shrink to a skirting-board stub instead of hiding outright, so you can
// see inside without them reading as a hole punched in the room. Toggled
// with a keyboard shortcut (see WALL_CUTAWAY_TOGGLE_KEY below) rather than
// always-on — deliberately NOT wired to the camera->orbit-target sightline
// (an earlier version was): the orbit pivot moves to wherever you last
// clicked (see onPointerDown's "grab and rotate" retargeting), including
// clicking a wall to select it for a material change — so a sightline test
// would frequently judge the very wall you just clicked as "in the way" and
// shrink it out from under your click, breaking wall selection. Using only
// the camera's position relative to each wall's outward-facing normal
// avoids that coupling entirely, and also sidesteps the raycast-against-
// thin-boxes corner-miss/flicker bugs an earlier version had (floating
// point gaps where two wall meshes meet at a corner).
// ---------------------------------------------------------------------------

const WALL_CUTAWAY_HEIGHT_M = 0.15; // stub height — like Sims' skirting-board cutaway
const WALL_CUTAWAY_LERP = 0.18;
const WALL_CUTAWAY_TOGGLE_KEY = 'c';
let cutawayEnabled = true;

function clamp01(value) {
  return Math.max(0, Math.min(1, value));
}

// Single entry point for changing cutawayEnabled, whichever side triggers
// it (the C hotkey below, or a toolbar button in Flutter via the
// 'setCutawayEnabled' bridge command) — always posts 'cutawayToggled' back
// so Flutter's toggle button stays in sync even when a hotkey changed it
// (same pattern as buildModeChanged for the Buduj tool).
function setCutawayEnabled(enabled) {
  cutawayEnabled = !!enabled;
  post('cutawayToggled', { enabled: cutawayEnabled });
}

// Global tool-switch hotkeys, same convention as floor_plan's canvas
// (floor_plan_canvas_keyboard.dart: bare letter keys switch tools from
// anywhere, Escape cancels an in-progress draw) — W/R jump straight into
// Buduj's wall/virtual-room sub-modes regardless of the currently selected
// toolbar tool, Escape cancels the active draw. Flutter's toolbar/panel
// state is kept in sync via the 'buildModeChanged' post below, since these
// keys are handled here (inside the webview) rather than in Flutter — a
// Flutter-side `Focus`/`onKeyEvent` listener the way floor_plan's canvas
// uses one can't see key events that land inside an embedded WebView.
function onKeyDown(event) {
  const tag = document.activeElement && document.activeElement.tagName;
  if (tag === 'INPUT' || tag === 'TEXTAREA') return;

  const key = event.key.toLowerCase();

  if (key === WALK_MODE_TOGGLE_KEY) {
    setWalkModeEnabled(!walkModeEnabled);
    return;
  }

  // W/A/S/D and the build-mode hotkeys collide on purpose (both use bare
  // W/R) — while walking, every other single-letter shortcut below has to
  // stand down so typing WASD to move doesn't also jump into Buduj. Escape
  // still works, just to exit walking instead of cancelling a draw.
  if (walkModeEnabled) {
    if (event.key === 'Escape') setWalkModeEnabled(false);
    return;
  }

  if (key === MEASURE_MODE_TOGGLE_KEY) {
    setMeasureModeEnabled(!measureModeEnabled);
    return;
  }

  // Same reasoning as the walk-mode guard above — stand every other
  // single-letter hotkey down while measuring, so W/R don't jump into Buduj
  // mid-measurement. Escape clears the current measurement and exits.
  if (measureModeEnabled) {
    if (event.key === 'Escape') setMeasureModeEnabled(false);
    return;
  }

  if (key === WALL_CUTAWAY_TOGGLE_KEY) {
    setCutawayEnabled(!cutawayEnabled);
    return;
  }

  // Saved camera views ("zakładki kamery", FINAL_VISION.md §2.3) — Ctrl+1..9
  // saves the current camera position/target into that slot, plain 1..9
  // recalls it (animated via the same shared tween as presets/minimap/
  // gizmo). Slots are purely in-memory (module state, not persisted in
  // RoomScene) — a saved view is a per-session viewing convenience, not
  // scene data.
  if (/^[1-9]$/.test(key)) {
    if (event.ctrlKey) {
      savedCameraViews.set(key, { position: camera.position.clone(), target: controls.target.clone() });
    } else {
      const saved = savedCameraViews.get(key);
      if (saved) animateCameraTo(saved.position, saved.target);
    }
    return;
  }

  // Global undo/redo (FINAL_VISION.md §2.2) — undo history itself lives
  // entirely in Flutter's Riverpod state (RoomSceneNotifier), so scene.js
  // can't perform this itself; it just notifies Flutter the same way
  // dragEnded/wallDrawn/etc. already do, and _onBridgeMessage forwards to
  // RoomSceneActions.undo()/redo() — the exact same call the existing
  // toolbar buttons already make.
  if (event.ctrlKey && (key === 'z' || key === 'y')) {
    post(key === 'z' ? 'undoRequested' : 'redoRequested', {});
    return;
  }

  // Delete/Backspace removes the selected furniture item (§2.2) — same
  // reasoning as undo/redo above: removal has to go through
  // RoomSceneActions.removeItem to stay in sync with Flutter's RoomScene
  // state, so this only requests it rather than deleting the mesh itself.
  if (selectedItemId && (key === 'delete' || key === 'backspace')) {
    post('deleteSelectedItemRequested', { id: selectedItemId });
    return;
  }

  // Arrow-key nudge for the selected item (§2.2) — Alt = fine step, Shift =
  // coarse step, matching floor_plan's own arrow-key nudge convention.
  // Reuses the EXISTING dragEnded message (same shape a mouse-drag release
  // already sends) so Flutter needs no new handler for this at all — a nudge
  // is just a drag with keyboard-sized steps instead of pixels.
  if (selectedItemId && ARROW_NUDGE_KEYS.has(key)) {
    nudgeSelectedItem(key, event);
    return;
  }

  if (key === 'w') {
    setBuildMode('wall', buildIsVirtual);
    post('buildModeChanged', { mode: buildMode });
    return;
  }

  if (key === 'r') {
    setBuildMode('room', buildIsVirtual);
    post('buildModeChanged', { mode: buildMode });
    return;
  }

  if (key === 'v' || key === 's') {
    if (!buildMode) return;
    cancelBuild();
    post('buildModeChanged', { mode: null });
    return;
  }

  if (event.key === 'Escape') {
    if (!buildMode) return;
    cancelBuild();
    post('buildModeChanged', { mode: null });
  }
}

// ---------------------------------------------------------------------------
// First-person walkthrough — see the module-level doc comment near
// walkModeEnabled for scope/limitations.
// ---------------------------------------------------------------------------

const WALK_MODE_TOGGLE_KEY = 'f';

function setWalkModeEnabled(enabled) {
  if (enabled === walkModeEnabled) return;
  walkModeEnabled = !!enabled;
  walkKeysPressed.clear();
  walkLooking = false;

  if (walkModeEnabled) {
    // Entering walk mode from Buduj would otherwise leave an orphaned
    // in-progress draw (and WASD would silently double as build hotkeys —
    // already guarded in onKeyDown, but cleanly exiting the draw is the
    // more honest behavior anyway).
    if (buildMode) {
      cancelBuild();
      post('buildModeChanged', { mode: null });
    }
    controls.enabled = false;

    // Derive yaw/pitch from the camera's current look direction so the
    // transition into walk mode doesn't snap the view — you keep looking
    // roughly where you were an instant ago, just from a walking camera now.
    const lookDir = new THREE.Vector3();
    camera.getWorldDirection(lookDir);
    walkYaw = Math.atan2(lookDir.x, lookDir.z);
    walkPitch = Math.asin(THREE.MathUtils.clamp(lookDir.y, -1, 1));
    camera.position.y = WALK_EYE_HEIGHT_M;
    applyWalkLookRotation();
  } else {
    controls.enabled = true;
    // Aim the orbit pivot a few meters ahead of where you were looking,
    // instead of leaving it wherever it last happened to be (which could be
    // far away/behind you after walking around) — keeps orbiting sane
    // immediately after leaving walk mode.
    const lookDir = new THREE.Vector3();
    camera.getWorldDirection(lookDir);
    controls.target.copy(camera.position).addScaledVector(lookDir, 3);
    controls.update();
  }

  post('walkModeChanged', { enabled: walkModeEnabled });
}

function applyWalkLookRotation() {
  camera.rotation.order = 'YXZ';
  camera.rotation.set(walkPitch, walkYaw, 0);
}

function updateWalkMovement(deltaSeconds) {
  if (!walkModeEnabled) return;

  let moveX = 0;
  let moveZ = 0; // forward is -Z in camera-local space, matching three.js convention
  if (walkKeysPressed.has('w') || walkKeysPressed.has('arrowup')) moveZ -= 1;
  if (walkKeysPressed.has('s') || walkKeysPressed.has('arrowdown')) moveZ += 1;
  if (walkKeysPressed.has('a') || walkKeysPressed.has('arrowleft')) moveX -= 1;
  if (walkKeysPressed.has('d') || walkKeysPressed.has('arrowright')) moveX += 1;
  if (moveX === 0 && moveZ === 0) return;

  const length = Math.hypot(moveX, moveZ);
  moveX /= length;
  moveZ /= length;

  // Forward/right vectors from yaw only (pitch ignored) — looking up/down
  // shouldn't change walking speed or lift you off the floor.
  const sinYaw = Math.sin(walkYaw);
  const cosYaw = Math.cos(walkYaw);
  const forwardX = sinYaw, forwardZ = cosYaw;
  const rightX = cosYaw, rightZ = -sinYaw;

  const distance = WALK_SPEED_MPS * deltaSeconds;
  const moveVecX = (forwardX * -moveZ + rightX * moveX) * distance;
  const moveVecZ = (forwardZ * -moveZ + rightZ * moveX) * distance;

  // Axis-separated sliding collision: resolve X and Z independently rather
  // than testing the full diagonal step as one unit — walking diagonally
  // into a wall then slides along it (one axis still moves) instead of
  // stopping dead, the standard cheap approximation of wall sliding.
  const currentX = camera.position.x;
  const currentZ = camera.position.z;

  let nextX = currentX + moveVecX;
  if (isWalkPositionBlocked(nextX, currentZ) || isItemPositionBlocked(nextX, currentZ)) nextX = currentX;

  let nextZ = currentZ + moveVecZ;
  if (isWalkPositionBlocked(nextX, nextZ) || isItemPositionBlocked(nextX, nextZ)) nextZ = currentZ;

  camera.position.x = nextX;
  camera.position.z = nextZ;
  camera.position.y = WALK_EYE_HEIGHT_M;
}

// Point-vs-wall collision test for walk mode. Each wall segment's solid
// ranges are stored in the wall's own local space (see buildWall's
// `collisionRanges`) — transforming the candidate world point into that
// space is just the inverse of the rotation `buildWall` applies to the
// wall Group (`group.rotation.y = -angle`, `group.position.set(midX, 0,
// midZ)`), i.e. rotate by +angle after subtracting the wall's midpoint.
function isWalkPositionBlocked(px, pz) {
  for (const seg of wallSegmentsById.values()) {
    if (!seg.collisionRanges || !seg.collisionRanges.length) continue;

    const relX = px - seg.midX;
    const relZ = pz - seg.midZ;
    const cosA = Math.cos(seg.angle);
    const sinA = Math.sin(seg.angle);
    const localX = relX * cosA + relZ * sinA; // position along the wall's length
    const localZ = -relX * sinA + relZ * cosA; // signed distance from centerline

    if (Math.abs(localZ) > seg.halfThickness + WALK_PLAYER_RADIUS_M) continue;

    for (const [xStart, xEnd] of seg.collisionRanges) {
      if (localX > xStart - WALK_PLAYER_RADIUS_M && localX < xEnd + WALK_PLAYER_RADIUS_M) {
        return true;
      }
    }
  }
  return false;
}

// Point-vs-furniture collision test for walk mode (FINAL_VISION.md §3.6's
// remaining gap — walls already collide, items didn't). Every placed item
// is a `DEFAULT_ITEM_SIZE`-sized box (real dimensions/models are Faza 2 —
// see buildItem's own TODO) sitting at `mesh.position`, rotated by
// `mesh.rotation.y` and uniformly scaled — treated as an oriented
// rectangular footprint on the floor, no height distinction needed (unlike
// wall openings, a placeholder furniture box has no "walk under it" gap).
// Transforming the candidate world point into the item's local space is
// the same inverse-rotation technique as `isWalkPositionBlocked`, just
// with a full 2D box (both X and Z half-extents) instead of a 1D range
// along a wall's length.
function isItemPositionBlocked(px, pz) {
  for (const mesh of itemMeshesById.values()) {
    const scale = mesh.scale.x || 1;
    const halfWidth = (DEFAULT_ITEM_SIZE.widthM * scale) / 2;
    const halfDepth = (DEFAULT_ITEM_SIZE.depthM * scale) / 2;

    const relX = px - mesh.position.x;
    const relZ = pz - mesh.position.z;
    const theta = mesh.rotation.y;
    const cosT = Math.cos(theta);
    const sinT = Math.sin(theta);
    const localX = relX * cosT - relZ * sinT;
    const localZ = relX * sinT + relZ * cosT;

    if (
      Math.abs(localX) < halfWidth + WALK_PLAYER_RADIUS_M &&
      Math.abs(localZ) < halfDepth + WALK_PLAYER_RADIUS_M
    ) {
      return true;
    }
  }
  return false;
}

function onWalkKeyDown(event) {
  if (!walkModeEnabled) return;
  const key = event.key.toLowerCase();
  if (WALK_MOVE_KEYS.has(key)) walkKeysPressed.add(key);
}

function onWalkKeyUp(event) {
  walkKeysPressed.delete(event.key.toLowerCase());
}

// ---------------------------------------------------------------------------
// Measuring tool ("Miarka") — see the module-level doc comment near
// measureModeEnabled for scope/behavior.
// ---------------------------------------------------------------------------

function setMeasureModeEnabled(enabled) {
  if (enabled === measureModeEnabled) return;
  measureModeEnabled = !!enabled;
  clearMeasurement();

  if (measureModeEnabled) {
    // Same reasoning as Buduj (setBuildMode) and walk mode: OrbitControls has
    // its own independent pointerdown listener on the same canvas, so a
    // click to place a measure point would otherwise also nudge/rotate the
    // camera.
    if (buildMode) {
      cancelBuild();
      post('buildModeChanged', { mode: null });
    }
    if (walkModeEnabled) setWalkModeEnabled(false);
    controls.enabled = false;
  } else {
    controls.enabled = true;
  }

  post('measureModeChanged', { enabled: measureModeEnabled });
}

function clearMeasurement() {
  measureStart = null;
  measureCompleted = null;
  while (measurePreviewGroup.children.length) {
    disposeObject(measurePreviewGroup.children.pop());
  }
  hideMeasureLabel();
}

function measureDistanceLabel(startPoint, endPoint) {
  const dx = endPoint.x - startPoint.x;
  const dz = endPoint.z - startPoint.z;
  const distanceM = Math.sqrt(dx * dx + dz * dz);
  return `${distanceM.toFixed(2)} m`;
}

function redrawMeasurePreview(startPoint, endPoint) {
  while (measurePreviewGroup.children.length) {
    disposeObject(measurePreviewGroup.children.pop());
  }

  [startPoint, endPoint].forEach((point) => {
    const marker = new THREE.Mesh(
      new THREE.SphereGeometry(0.05, 12, 12),
      new THREE.MeshBasicMaterial({ color: MEASURE_LINE_COLOR }),
    );
    marker.position.set(point.x, 0.05, point.z);
    measurePreviewGroup.add(marker);
  });

  const positions = [startPoint.x, 0.05, startPoint.z, endPoint.x, 0.05, endPoint.z];
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  const line = new THREE.Line(geometry, new THREE.LineBasicMaterial({ color: MEASURE_LINE_COLOR }));
  measurePreviewGroup.add(line);
}

// Keeps the HTML label glued to the midpoint of the current measurement as
// the camera orbits — called every frame from animate(), not just on
// click/move, since the label's SCREEN position depends on where the camera
// currently is, unlike the 3D line/markers which just sit in world space.
function updateMeasureLabelPosition() {
  const active = measureCompleted || (measureStart && measureLiveEnd);
  if (!active) {
    hideMeasureLabel();
    return;
  }

  const { start, end } = measureCompleted || { start: measureStart, end: measureLiveEnd };
  const midWorld = new THREE.Vector3((start.x + end.x) / 2, 0.15, (start.z + end.z) / 2);
  const ndc = midWorld.clone().project(camera);

  // Behind the camera — hide rather than show a label warped to the wrong
  // side of the screen.
  if (ndc.z > 1) {
    hideMeasureLabel();
    return;
  }

  const rect = renderer.domElement.getBoundingClientRect();
  const screenX = (ndc.x * 0.5 + 0.5) * rect.width;
  const screenY = (-ndc.y * 0.5 + 0.5) * rect.height;
  showMeasureLabel(measureDistanceLabel(start, end), screenX, screenY);
}

function showMeasureLabel(text, screenX, screenY) {
  const label = document.getElementById('measure-label');
  if (!label) return;
  label.textContent = text;
  label.style.left = `${screenX}px`;
  label.style.top = `${screenY}px`;
  label.style.display = 'block';
}

function hideMeasureLabel() {
  const label = document.getElementById('measure-label');
  if (label) label.style.display = 'none';
}

function setDimensionsEnabled(enabled) {
  dimensionsEnabled = enabled;
  if (!enabled) {
    dimensionLabelDivsByWallId.forEach((div) => div.remove());
    dimensionLabelDivsByWallId.clear();
  }
}

// Reuses wallSegmentsById (already kept in sync by loadScene/addWall/
// removeWall for build-mode snapping) for endpoints/length, and each wall's
// own Group.userData.baseHeightM (buildWall) for label height — no
// duplicate per-wall bookkeeping needed for this feature.
function updateDimensionLabels() {
  if (!dimensionsEnabled) return;

  const container = document.getElementById('dimension-labels');
  if (!container) return;

  const rect = renderer.domElement.getBoundingClientRect();
  const seenWallIds = new Set();

  wallSegmentsById.forEach((seg, wallId) => {
    seenWallIds.add(wallId);

    const dx = seg.x2 - seg.x1;
    const dz = seg.z2 - seg.z1;
    const length = Math.hypot(dx, dz);
    if (length <= 0.001) return;

    let div = dimensionLabelDivsByWallId.get(wallId);
    if (!div) {
      div = document.createElement('div');
      div.className = 'dimension-label';
      container.appendChild(div);
      dimensionLabelDivsByWallId.set(wallId, div);
    }

    const wallGroup = wallDefaultMaterialMeshesByWallId.get(wallId);
    const wallHeight = (wallGroup && wallGroup.userData.baseHeightM) || 2.6;

    const midWorld = new THREE.Vector3(
      (seg.x1 + seg.x2) / 2,
      wallHeight + DIMENSION_LABEL_HEIGHT_OFFSET_M,
      (seg.z1 + seg.z2) / 2,
    );
    const ndc = midWorld.clone().project(camera);

    if (ndc.z > 1) {
      div.style.display = 'none';
      return;
    }

    div.style.left = `${(ndc.x * 0.5 + 0.5) * rect.width}px`;
    div.style.top = `${(-ndc.y * 0.5 + 0.5) * rect.height}px`;
    div.textContent = `${length.toFixed(2)} m`;
    div.style.display = 'block';
  });

  // Drop labels for walls removed since the last frame (removeWall/loadScene
  // don't need to know about this feature at all — cleanup happens lazily
  // here instead).
  dimensionLabelDivsByWallId.forEach((div, wallId) => {
    if (seenWallIds.has(wallId)) return;
    div.remove();
    dimensionLabelDivsByWallId.delete(wallId);
  });
}

function handleMeasureClick(event) {
  updatePointerNdc(event);
  raycaster.setFromCamera(pointerNdc, camera);

  const hitPoint = new THREE.Vector3();
  if (!raycaster.ray.intersectPlane(floorPlane, hitPoint)) return;

  const snapped = snapBuildPoint(hitPoint.x, hitPoint.z);

  if (!measureStart) {
    measureStart = { x: snapped.x, z: snapped.z };
    measureCompleted = null;
    measureLiveEnd = null;
    redrawMeasurePreview(measureStart, measureStart);
    return;
  }

  const end = { x: snapped.x, z: snapped.z };
  measureCompleted = { start: measureStart, end };
  measureStart = null;
  measureLiveEnd = null;
  redrawMeasurePreview(measureCompleted.start, measureCompleted.end);
}

function updateMeasureRubberBand(event) {
  if (!measureStart) return;

  updatePointerNdc(event);
  raycaster.setFromCamera(pointerNdc, camera);
  const hitPoint = new THREE.Vector3();
  if (!raycaster.ray.intersectPlane(floorPlane, hitPoint)) return;

  const snapped = snapBuildPoint(hitPoint.x, hitPoint.z);
  measureLiveEnd = { x: snapped.x, z: snapped.z };
  redrawMeasurePreview(measureStart, measureLiveEnd);
}

// ---------------------------------------------------------------------------
// Minimap — see the module-level doc comment near minimapCamera.
// ---------------------------------------------------------------------------

function setupMinimap() {
  minimapCamera = new THREE.OrthographicCamera(-5, 5, 5, -5, 0.1, 500);
  minimapCamera.layers.enable(MINIMAP_LAYER);

  // A small flat triangle showing the main camera's position + facing
  // direction, laid flat on the ground (rotateX, same convention as
  // buildRoomFloor) and raised above wall height so it's never occluded
  // when seen from directly above. Only on MINIMAP_LAYER — the main
  // (perspective) camera never enables that layer, so this never appears
  // in the normal 3D view despite living in the same `scene`.
  const shape = new THREE.Shape();
  shape.moveTo(0, 0.22);
  shape.lineTo(-0.11, -0.11);
  shape.lineTo(0.11, -0.11);
  shape.closePath();
  const indicatorGeometry = new THREE.ShapeGeometry(shape);
  indicatorGeometry.rotateX(Math.PI / 2);
  minimapIndicator = new THREE.Mesh(
    indicatorGeometry,
    new THREE.MeshBasicMaterial({ color: 0xffd166, side: THREE.DoubleSide }),
  );
  minimapIndicator.position.y = 4;
  minimapIndicator.layers.set(MINIMAP_LAYER);
  scene.add(minimapIndicator);
}

// Fits the minimap's orthographic frustum to the current scene's wall
// bounds (with padding) — called whenever the wall set changes (loadScene,
// addWall, removeWall) so the minimap always frames the whole plan,
// regardless of room size. No walls yet (empty scene) leaves it at
// whatever it was previously — nothing sensible to fit to.
function fitMinimapCameraToScene() {
  if (!minimapCamera || wallSegmentsById.size === 0) return;

  let minX = Infinity, maxX = -Infinity, minZ = Infinity, maxZ = -Infinity;
  wallSegmentsById.forEach((seg) => {
    minX = Math.min(minX, seg.x1, seg.x2);
    maxX = Math.max(maxX, seg.x1, seg.x2);
    minZ = Math.min(minZ, seg.z1, seg.z2);
    maxZ = Math.max(maxZ, seg.z1, seg.z2);
  });

  minimapCenterX = (minX + maxX) / 2;
  minimapCenterZ = (minZ + maxZ) / 2;
  minimapHalfExtent = Math.max(maxX - minX, maxZ - minZ) / 2 + MINIMAP_PADDING_M;

  minimapCamera.left = -minimapHalfExtent;
  minimapCamera.right = minimapHalfExtent;
  minimapCamera.top = minimapHalfExtent;
  minimapCamera.bottom = -minimapHalfExtent;
  minimapCamera.position.set(minimapCenterX, 50, minimapCenterZ);
  // up = (0,0,-1) resolves the otherwise-ambiguous roll of a straight-down
  // lookAt (forward and up would be parallel with the default (0,1,0) up) —
  // the actual direction it picks doesn't matter for correctness, since
  // screenToMinimapWorld below always inverts through this exact camera,
  // whatever convention it ends up using.
  minimapCamera.up.set(0, 0, -1);
  minimapCamera.lookAt(minimapCenterX, 0, minimapCenterZ);
  minimapCamera.updateProjectionMatrix();
}

function updateMinimapIndicator() {
  if (!minimapIndicator) return;
  minimapIndicator.position.x = camera.position.x;
  minimapIndicator.position.z = camera.position.z;

  const dir = new THREE.Vector3();
  camera.getWorldDirection(dir);
  const yaw = Math.atan2(dir.x, dir.z);
  minimapIndicator.rotation.y = -yaw;
}

function minimapScreenRect() {
  const rect = renderer.domElement.getBoundingClientRect();
  const bottom = rect.height - MINIMAP_MARGIN_PX;
  return {
    left: MINIMAP_MARGIN_PX,
    top: bottom - MINIMAP_SIZE_PX,
    size: MINIMAP_SIZE_PX,
    canvasHeight: rect.height,
  };
}

// Renders the minimap into a scissored rect in the corner of the SAME
// canvas, right after the main render — restricting the existing
// renderer's viewport/scissor for a second render() call, rather than
// render-to-texture + draw-a-quad or a second WebGL context/canvas.
function renderMinimap() {
  if (!minimapCamera || wallSegmentsById.size === 0) {
    hideMinimapFrame();
    return;
  }

  updateMinimapIndicator();

  const rect = minimapScreenRect();
  showMinimapFrame(rect);

  renderer.setScissorTest(true);
  renderer.setViewport(rect.left, rect.canvasHeight - rect.top - rect.size, rect.size, rect.size);
  renderer.setScissor(rect.left, rect.canvasHeight - rect.top - rect.size, rect.size, rect.size);
  renderer.render(scene, minimapCamera);

  renderer.setScissorTest(false);
  renderer.setViewport(0, 0, renderer.domElement.clientWidth, renderer.domElement.clientHeight);
}

function showMinimapFrame(rect) {
  const frame = document.getElementById('minimap-frame');
  if (!frame) return;
  frame.style.left = `${rect.left}px`;
  frame.style.top = `${rect.top}px`;
  frame.style.width = `${rect.size}px`;
  frame.style.height = `${rect.size}px`;
  frame.style.display = 'block';
}

function hideMinimapFrame() {
  const frame = document.getElementById('minimap-frame');
  if (frame) frame.style.display = 'none';
}

function isPointerOverMinimap(event) {
  if (!minimapCamera || wallSegmentsById.size === 0) return false;
  const rect = minimapScreenRect();
  const canvasRect = renderer.domElement.getBoundingClientRect();
  const mx = event.clientX - canvasRect.left;
  const my = event.clientY - canvasRect.top;
  return mx >= rect.left && mx <= rect.left + rect.size && my >= rect.top && my <= rect.top + rect.size;
}

// Clicking the minimap teleports the main camera to a top-down view
// centered on the clicked point — same preset shape as
// setCameraPreset('topDown'), just recentered instead of always (0,0,0).
// Uses Camera.unproject (not hand-derived trig) to invert screen -> world,
// so it's automatically correct regardless of the minimap camera's exact
// up-vector/rotation convention.
function handleMinimapClick(event) {
  const rect = minimapScreenRect();
  const canvasRect = renderer.domElement.getBoundingClientRect();
  const mx = event.clientX - canvasRect.left;
  const my = event.clientY - canvasRect.top;

  const ndcX = ((mx - rect.left) / rect.size) * 2 - 1;
  const ndcY = -(((my - rect.top) / rect.size) * 2 - 1);
  const worldPoint = new THREE.Vector3(ndcX, ndcY, 0).unproject(minimapCamera);

  if (walkModeEnabled) setWalkModeEnabled(false);
  animateCameraTo(
    new THREE.Vector3(worldPoint.x, 12, worldPoint.z + 0.001),
    new THREE.Vector3(worldPoint.x, 0, worldPoint.z),
  );
}

// Fully separate mini-scene (not `scene`, no layers needed — unlike the
// minimap, whose indicator has to share the room's own geometry, the axis
// gizmo has nothing to do with room content) with 3 colored arms
// (X=red, Y=green, Z=blue) and a clickable sphere at each end — bright/
// solid on the positive end, dim/translucent on the negative end, the same
// solid/dim convention as SketchUp/Fusion360's axis gizmos so a returning
// user's existing intuition transfers.
function setupAxisGizmo() {
  axisGizmoScene = new THREE.Scene();

  axisGizmoCamera = new THREE.OrthographicCamera(
    -AXIS_GIZMO_ARM_LENGTH * 1.6, AXIS_GIZMO_ARM_LENGTH * 1.6,
    AXIS_GIZMO_ARM_LENGTH * 1.6, -AXIS_GIZMO_ARM_LENGTH * 1.6,
    0.1, 20,
  );

  const axes = [
    { dir: new THREE.Vector3(1, 0, 0), color: 0xe25555, label: 'x' },
    { dir: new THREE.Vector3(0, 1, 0), color: 0x5bc25b, label: 'y' },
    { dir: new THREE.Vector3(0, 0, 1), color: 0x4d8fe2, label: 'z' },
  ];

  axes.forEach(({ dir, color, label }) => {
    [1, -1].forEach((sign) => {
      const end = dir.clone().multiplyScalar(AXIS_GIZMO_ARM_LENGTH * sign);

      const lineGeometry = new THREE.BufferGeometry().setFromPoints([
        new THREE.Vector3(0, 0, 0),
        end,
      ]);
      axisGizmoScene.add(new THREE.Line(lineGeometry, new THREE.LineBasicMaterial({ color })));

      const sphere = new THREE.Mesh(
        new THREE.SphereGeometry(AXIS_GIZMO_SPHERE_RADIUS, 16, 16),
        new THREE.MeshBasicMaterial({
          color,
          transparent: sign < 0,
          opacity: sign < 0 ? 0.35 : 1,
        }),
      );
      sphere.position.copy(end);
      sphere.userData = { kind: 'gizmoAxis', axis: label, sign };
      axisGizmoScene.add(sphere);
    });
  });
}

// Mirrors the MAIN camera's rotation (not position) onto the gizmo camera —
// positioned along the inverse of the main camera's look direction at a
// fixed distance from the gizmo scene's own origin, so the little axis
// widget always shows "which way am I currently looking," independent of
// where the main camera actually is in room-space.
function updateAxisGizmoCamera() {
  const direction = new THREE.Vector3();
  camera.getWorldDirection(direction);
  axisGizmoCamera.position.copy(direction).multiplyScalar(-AXIS_GIZMO_DISTANCE);
  axisGizmoCamera.up.copy(camera.up);
  axisGizmoCamera.lookAt(0, 0, 0);
}

function axisGizmoScreenRect() {
  const rect = renderer.domElement.getBoundingClientRect();
  return {
    left: rect.width - AXIS_GIZMO_MARGIN_PX - AXIS_GIZMO_SIZE_PX,
    top: AXIS_GIZMO_MARGIN_PX,
    size: AXIS_GIZMO_SIZE_PX,
    canvasHeight: rect.height,
  };
}

// Same scissored-corner-of-the-same-canvas technique as renderMinimap —
// always shown (unlike the minimap, which hides for an empty scene: an
// orientation gizmo is meaningful even with nothing loaded yet).
function renderAxisGizmo() {
  updateAxisGizmoCamera();

  const rect = axisGizmoScreenRect();
  renderer.setScissorTest(true);
  renderer.setViewport(rect.left, rect.canvasHeight - rect.top - rect.size, rect.size, rect.size);
  renderer.setScissor(rect.left, rect.canvasHeight - rect.top - rect.size, rect.size, rect.size);
  renderer.render(axisGizmoScene, axisGizmoCamera);

  renderer.setScissorTest(false);
  renderer.setViewport(0, 0, renderer.domElement.clientWidth, renderer.domElement.clientHeight);
}

function isPointerOverAxisGizmo(event) {
  const rect = axisGizmoScreenRect();
  const canvasRect = renderer.domElement.getBoundingClientRect();
  const mx = event.clientX - canvasRect.left;
  const my = event.clientY - canvasRect.top;
  return mx >= rect.left && mx <= rect.left + rect.size && my >= rect.top && my <= rect.top + rect.size;
}

// Snaps the main camera to look straight down the clicked axis, keeping
// the current distance to controls.target (so clicking the gizmo reorients
// without also zooming) — the actual "easy to orbit like in CAD" payoff.
// Same instant-snap convention as setCameraPreset (no tweening exists
// anywhere else in this codebase).
function handleAxisGizmoClick(event) {
  const rect = axisGizmoScreenRect();
  const canvasRect = renderer.domElement.getBoundingClientRect();
  const mx = event.clientX - canvasRect.left;
  const my = event.clientY - canvasRect.top;

  const ndcX = ((mx - rect.left) / rect.size) * 2 - 1;
  const ndcY = -(((my - rect.top) / rect.size) * 2 - 1);

  const gizmoRaycaster = new THREE.Raycaster();
  gizmoRaycaster.setFromCamera({ x: ndcX, y: ndcY }, axisGizmoCamera);
  const hits = gizmoRaycaster.intersectObjects(axisGizmoScene.children, false)
    .filter((hit) => hit.object.userData && hit.object.userData.kind === 'gizmoAxis');
  if (!hits.length) return;

  const { axis, sign } = hits[0].object.userData;
  const direction = new THREE.Vector3(
    axis === 'x' ? sign : 0,
    axis === 'y' ? sign : 0,
    axis === 'z' ? sign : 0,
  );

  if (walkModeEnabled) setWalkModeEnabled(false);

  const distance = camera.position.distanceTo(controls.target);
  const toPos = controls.target.clone().addScaledVector(direction, distance);
  // A near-exact +Y/-Y view puts the look direction parallel to the
  // default (0,1,0) up vector, which OrbitControls can't resolve into a
  // stable orientation (the same gimbal-lock case setCameraPreset('topDown')
  // already sidesteps with its own tiny epsilon) — nudge along +Z so the
  // resulting view is well-defined instead of an indeterminate roll.
  if (axis === 'y') toPos.z += 0.001;
  animateCameraTo(toPos, controls.target);
}

// Outward normal per wall (pointing away from the room's interior) is
// computed once, right after a scene finishes loading — see
// computeWallOutwardNormals — and cached on each wallSegmentsById entry, so
// the per-frame cutaway check below is a single dot product per wall.
function computeWallOutwardNormals() {
  const segments = [...wallSegmentsById.values()];
  if (!segments.length) return;

  let centroidX = 0, centroidZ = 0;
  segments.forEach((seg) => {
    centroidX += (seg.x1 + seg.x2) / 2;
    centroidZ += (seg.z1 + seg.z2) / 2;
  });
  centroidX /= segments.length;
  centroidZ /= segments.length;

  segments.forEach((seg) => {
    const dx = seg.x2 - seg.x1, dz = seg.z2 - seg.z1;
    const len = Math.sqrt(dx * dx + dz * dz) || 1;
    let nx = -dz / len, nz = dx / len;

    const midX = (seg.x1 + seg.x2) / 2, midZ = (seg.z1 + seg.z2) / 2;
    if ((midX - centroidX) * nx + (midZ - centroidZ) * nz < 0) {
      nx = -nx;
      nz = -nz;
    }

    seg.outwardX = nx;
    seg.outwardZ = nz;
    seg.midX = midX;
    seg.midZ = midZ;
  });

  // Every call site that changes the wall set (loadScene, addWall,
  // removeWall) already calls this function right after — piggybacking the
  // minimap's frustum-fit here guarantees it stays in sync without needing
  // a matching call at each of those sites individually.
  fitMinimapCameraToScene();
}

// ---------------------------------------------------------------------------
// Furniture wall-snapping: when an item's center comes within
// ITEM_WALL_SNAP_DISTANCE_M of a wall, pull it flush against that wall
// (clearance = wall half-thickness + item half-depth, so it can never clip
// through) and orient it back-to-the-wall automatically. Runs on initial
// placement and continuously while dragging — NOT on inspector rotation
// edits (those go through moveItem directly, a separate code path), which
// is what lets a manual rotation override stick until the item is dragged
// near a wall again.
// ---------------------------------------------------------------------------

const ITEM_WALL_SNAP_DISTANCE_M = 0.5;

function pointToSegmentInfo(px, pz, x1, z1, x2, z2) {
  const dx = x2 - x1, dz = z2 - z1;
  const lenSq = dx * dx + dz * dz;
  const t = lenSq > 1e-9 ? clamp01(((px - x1) * dx + (pz - z1) * dz) / lenSq) : 0;
  const footX = x1 + dx * t, footZ = z1 + dz * t;
  const ddx = px - footX, ddz = pz - footZ;
  return { distSq: ddx * ddx + ddz * ddz, footX, footZ, dirX: dx, dirZ: dz, len: Math.sqrt(lenSq) };
}

// Arrow-key nudge for the selected item (FINAL_VISION.md §2.2) — up/down/
// left/right move along world Z/X directly (a top-down-plan convention,
// not camera-relative, matching floor_plan's own arrow-key nudge) rather
// than the camera's current facing direction.
const ARROW_NUDGE_KEYS = new Set(['arrowup', 'arrowdown', 'arrowleft', 'arrowright']);
const ITEM_NUDGE_STEP_M = 0.05;
const ITEM_NUDGE_STEP_FINE_M = 0.01;
const ITEM_NUDGE_STEP_COARSE_M = 0.25;

function nudgeSelectedItem(key, event) {
  const mesh = itemMeshesById.get(selectedItemId);
  if (!mesh) return;

  const step = event.altKey
    ? ITEM_NUDGE_STEP_FINE_M
    : event.shiftKey
      ? ITEM_NUDGE_STEP_COARSE_M
      : ITEM_NUDGE_STEP_M;

  if (key === 'arrowup') mesh.position.z -= step;
  else if (key === 'arrowdown') mesh.position.z += step;
  else if (key === 'arrowleft') mesh.position.x -= step;
  else if (key === 'arrowright') mesh.position.x += step;

  applyWallSnap(mesh);
  post('dragEnded', {
    id: selectedItemId,
    position: {
      x: mesh.position.x,
      y: mesh.position.z,
      z: mesh.position.y - DEFAULT_ITEM_SIZE.heightM / 2,
    },
    rotation_deg: -mesh.rotation.y * (180 / Math.PI),
  });
}

function applyWallSnap(mesh) {
  if (wallSegmentsById.size === 0) return;

  let nearest = null;
  wallSegmentsById.forEach((seg, wallId) => {
    const info = pointToSegmentInfo(mesh.position.x, mesh.position.z, seg.x1, seg.z1, seg.x2, seg.z2);
    if (!nearest || info.distSq < nearest.info.distSq) nearest = { seg, info };
  });

  if (Math.sqrt(nearest.info.distSq) > ITEM_WALL_SNAP_DISTANCE_M) return;

  const itemHalfDepth = (mesh.userData.depthM || DEFAULT_ITEM_SIZE.depthM) / 2;
  const clearance = nearest.seg.halfThickness + itemHalfDepth;
  const len = nearest.info.len || 1;

  let nx = -nearest.info.dirZ / len, nz = nearest.info.dirX / len;
  const toItemX = mesh.position.x - nearest.info.footX;
  const toItemZ = mesh.position.z - nearest.info.footZ;
  if (nx * toItemX + nz * toItemZ < 0) {
    nx = -nx;
    nz = -nz;
  }

  mesh.position.x = nearest.info.footX + nx * clearance;
  mesh.position.z = nearest.info.footZ + nz * clearance;
  // Local -Z (the front indicator strip) should point along the wall
  // normal, into the room — mirrors the rotation.y = -angle convention
  // used everywhere else in this file (see wallVector/dragEnded).
  mesh.rotation.y = Math.atan2(-nx, -nz);
}

function updateWallCutaway() {
  const cx = camera.position.x, cz = camera.position.z;

  wallDefaultMaterialMeshesByWallId.forEach((wallGroup, wallId) => {
    const seg = wallSegmentsById.get(wallId);
    const baseHeight = wallGroup.userData.baseHeightM;

    // Camera is on the exterior side of this wall (outward normal points
    // roughly toward it) => this wall sits between the camera and the
    // room's interior and should shrink out of the way.
    const inTheWay =
      cutawayEnabled &&
      seg &&
      seg.outwardX !== undefined &&
      (cx - seg.midX) * seg.outwardX + (cz - seg.midZ) * seg.outwardZ > 0;

    const targetHeight = inTheWay ? Math.min(WALL_CUTAWAY_HEIGHT_M, baseHeight) : baseHeight;
    const targetScaleY = targetHeight / baseHeight;
    wallGroup.scale.y += (targetScaleY - wallGroup.scale.y) * WALL_CUTAWAY_LERP;
    // wallGroup.position.y is intentionally never touched (stays 0, see
    // buildWall) — each segment's own Y position is already absolute
    // (0..baseHeight, not centered around the group origin), so
    // floor-touching segments stay grounded as the group scales down,
    // without needing the old single-box "recenter position.y" step.

    // Mirror onto the (always-full-size-until-now) click hitbox too — a
    // minimized wall's hitbox used to stay at full height regardless, so a
    // click aimed at whatever's now visible past/above it (a wall further
    // in, furniture, the floor) hit the invisible stub instead. The round 8
    // fix (decoupling hitbox size from cutaway) was for a different
    // problem — a wall wrongly shrunk by the outward-normal heuristic while
    // the user stands inside a concave room/near a partition wall, making
    // it unclickable at eye height. Tracking the SAME animated scale here
    // keeps that fix (a shrunk hitbox is still exactly as tall as what's
    // drawn, never shorter) while no longer blocking clicks through a
    // *correctly* minimized wall. Fully disabling cutaway (see
    // cutawayEnabled / the toolbar toggle) remains the answer when the
    // heuristic itself is the problem, not the hitbox size.
    // The hitbox is still a single box centered at height/2 (it ignores
    // openings on purpose — see buildWall), so it still needs the old
    // "recenter position.y" step unlike the group above.
    const hitboxMesh = wallHitboxMeshesByWallId.get(wallId);
    if (hitboxMesh) {
      hitboxMesh.scale.y = wallGroup.scale.y;
      hitboxMesh.position.y = (baseHeight * wallGroup.scale.y) / 2;
    }
  });
}

// ---------------------------------------------------------------------------
// RoomScene -> three.js geometry
// ---------------------------------------------------------------------------

function clearRoomGroup() {
  while (roomGroup.children.length) {
    const child = roomGroup.children.pop();
    disposeObject(child);
  }
  itemMeshesById.clear();
  wallZoneMeshesByZoneId.clear();
  wallDefaultMaterialMeshesByWallId.clear();
  wallHitboxMeshesByWallId.clear();
  floorMeshesByRoomId.clear();
  wallSegmentsById.clear();
  selectedItemId = null;
  selectedWallId = null;
  selectedRoomId = null;
  cancelBuild();
  clearMeasurement();
  clearWallEndpointHandles();
  wallEndpointDragState = null;
  placingOpeningKind = null;
  clearAdjacentFloorGroups();
  floorLayerCounter = 0;
  activeDynamicLightCount = 0;
}

function disposeObject(object) {
  object.traverse((node) => {
    if (node.geometry) node.geometry.dispose();
    if (node.material) {
      if (Array.isArray(node.material)) node.material.forEach((m) => m.dispose());
      else node.material.dispose();
    }
  });
}

function wallVector(wall) {
  const dx = wall.end.x - wall.start.x;
  const dz = wall.end.y - wall.start.y; // RoomScene's 2D y maps to three.js z (ground plane)
  const length = Math.sqrt(dx * dx + dz * dz);
  const angle = Math.atan2(dz, dx);
  return { dx, dz, length, angle };
}

// BoxGeometry's default face-group order is [+x, -x, +y, -y, +z, -z],
// matching material array indices 0..5 one-to-one. A wall's two "room-facing"
// sides are the +z/-z faces (index 4/5) in the wall's own local space —
// index 4 is the same "front" side the wall-zone overlay boxes already sit
// against (see getOrCreateWallZoneMesh's local Z offset). Painting only
// index 4 means a wall between two rooms can show a different material on
// each side, instead of the whole box being tinted uniformly.
const WALL_FRONT_MATERIAL_INDEX = 4;
const WALL_BACK_MATERIAL_INDEX = 5;

// Splits a wall's [-length/2, length/2] x [0, height] rectangle into the
// solid rectangles that remain once every opening on it is cut out — one
// "below sill" strip and one "above lintel" strip per opening (only the
// ones with positive extent), plus whatever's left between/around them.
// Assumes openings on the same wall don't overlap (true for real floor
// plans); an out-of-order/overlapping opening is just skipped rather than
// producing inverted geometry. No true CSG needed since walls are flat
// rectangles and openings are always axis-aligned sub-rectangles of them.
function computeWallSolidRects(openings, length, height) {
  const half = length / 2;
  if (!openings || !openings.length) {
    return [{ xStart: -half, xEnd: half, yStart: 0, yEnd: height }];
  }

  const sorted = [...openings].sort((a, b) => a.position - b.position);
  const rects = [];
  let cursor = -half;

  sorted.forEach((opening) => {
    const centerX = opening.position * length - half;
    const halfWidth = (opening.width_m || 0.9) / 2;
    const openStart = Math.max(-half, centerX - halfWidth);
    const openEnd = Math.min(half, centerX + halfWidth);
    if (openEnd <= cursor) return; // overlaps the previous opening — skip

    const sill = Math.max(0, opening.sill_height_m || 0);
    const top = Math.min(height, sill + (opening.height_m || 2.05));

    if (openStart > cursor) {
      rects.push({ xStart: cursor, xEnd: openStart, yStart: 0, yEnd: height });
    }
    if (sill > 0.001) {
      rects.push({ xStart: openStart, xEnd: openEnd, yStart: 0, yEnd: sill });
    }
    if (top < height - 0.001) {
      rects.push({ xStart: openStart, xEnd: openEnd, yStart: top, yEnd: height });
    }
    cursor = Math.max(cursor, openEnd);
  });

  if (cursor < half - 0.001) {
    rects.push({ xStart: cursor, xEnd: half, yStart: 0, yEnd: height });
  }

  return rects.filter((r) => r.xEnd - r.xStart > 0.001 && r.yEnd - r.yStart > 0.001);
}

// Extends only the rects touching the wall's TRUE endpoints by half the
// wall's thickness — the same corner-fill fix as before (see the "flush
// corners" fix), just no longer applied uniformly to a single box, since an
// opening near one end must not have its edge pushed into the opening gap.
function extendOuterEdgesForCornerFill(rects, length, thickness) {
  const half = length / 2;
  rects.forEach((rect) => {
    if (Math.abs(rect.xStart + half) < 0.001) rect.xStart -= thickness / 2;
    if (Math.abs(rect.xEnd - half) < 0.001) rect.xEnd += thickness / 2;
  });
}

// A wall is a Group of one or more box "segments" (not a single Mesh) so a
// door/window opening can be a real gap in the geometry instead of a solid
// box regardless of data — see computeWallSolidRects. The group sits at
// floor level (position.y = 0) with each segment positioned at its own
// ABSOLUTE height range (0..height), not centered on the group origin —
// that's what lets updateWallCutaway shrink the group by scaling scale.y
// alone (floor-touching segments stay grounded automatically) without
// needing to also recompute position.y every frame the way the old
// single-box mesh did.
function buildWall(wall, openings) {
  const { length, angle } = wallVector(wall);
  if (length <= 0.001) return;

  const thickness = wall.thickness_m || 0.15;
  const height = wall.height_m || 2.6;

  const rects = computeWallSolidRects(openings, length, height);
  extendOuterEdgesForCornerFill(rects, length, thickness);

  // Collision ranges (local-X intervals, along the wall's centerline) for
  // walk-mode collision — see WALK_BODY_TOP_M's doc comment for why this is
  // "does this rect start below body-top height", not an eye-height probe.
  const collisionRanges = rects
    .filter((rect) => rect.yStart < WALK_BODY_TOP_M)
    .map((rect) => [rect.xStart, rect.xEnd]);

  const baseColor = wall.is_virtual ? 0x4a6b8a : 0xd9d3c7;
  const materialOpts = {
    color: baseColor,
    transparent: wall.is_virtual,
    opacity: wall.is_virtual ? 0.35 : 1,
  };

  const group = new THREE.Group();
  rects.forEach((rect) => {
    const segGeometry = new THREE.BoxGeometry(rect.xEnd - rect.xStart, rect.yEnd - rect.yStart, thickness);
    // 6 independent material instances (one per face) so front/back can be
    // tinted separately without one .color.set() call recoloring both sides.
    const materials = Array.from({ length: 6 }, () => new THREE.MeshStandardMaterial(materialOpts));
    const segmentMesh = new THREE.Mesh(segGeometry, materials);
    segmentMesh.position.set((rect.xStart + rect.xEnd) / 2, (rect.yStart + rect.yEnd) / 2, 0);
    segmentMesh.userData = { kind: 'wallSegment' };
    group.add(segmentMesh);
  });

  const midX = (wall.start.x + wall.end.x) / 2;
  const midZ = (wall.start.y + wall.end.y) / 2;

  group.position.set(midX, 0, midZ);
  group.rotation.y = -angle;
  group.userData = {
    kind: 'wall',
    wallId: wall.id,
    baseHeightM: height,
    trueLengthM: length,
    thicknessM: thickness,
  };

  roomGroup.add(group);
  wallDefaultMaterialMeshesByWallId.set(wall.id, group);
  wallSegmentsById.set(wall.id, {
    x1: wall.start.x,
    z1: wall.start.y,
    x2: wall.end.x,
    z2: wall.end.y,
    halfThickness: thickness / 2,
    midX,
    midZ,
    angle,
    collisionRanges,
  });

  // Full-height, always-clickable hitbox — see wallHitboxMeshesByWallId's
  // doc comment. Deliberately IGNORES openings (a single box spanning the
  // wall's full extent, same as before openings existed) — clicking through
  // a door-shaped gap to hit whatever's on the other side is a nicety, not
  // implemented, since it would need its own opening-aware hit-test; this
  // keeps wall selection reliable everywhere else (see round 8/11's fixes)
  // at the cost of not being able to click "past" a wall through its own
  // door opening. Kept as a plain symmetric box (position.y = height/2,
  // unlike the group above) since it's unaffected by the segment split.
  // side: DoubleSide is required — Raycaster respects material.side just
  // like rendering does, and MeshBasicMaterial defaults to FrontSide, which
  // silently culls hits coming from whichever face isn't the "front" one
  // (three.js's backfaceCulling check in Mesh.raycast). That's exactly the
  // "can only select a wall from the outside, not from inside the room"
  // bug — half the box's faces (the ones facing into whichever rooms sit on
  // the FrontSide) were never hittable via a ray from the other side at all.
  const hitboxGeometry = new THREE.BoxGeometry(length + thickness, height, thickness);
  const hitboxMesh = new THREE.Mesh(
    hitboxGeometry,
    new THREE.MeshBasicMaterial({
      transparent: true,
      opacity: 0,
      depthWrite: false,
      side: THREE.DoubleSide,
    }),
  );
  hitboxMesh.position.set(midX, height / 2, midZ);
  hitboxMesh.rotation.y = -angle;
  hitboxMesh.userData = { kind: 'wallHitbox', wallId: wall.id };
  roomGroup.add(hitboxMesh);
  wallHitboxMeshesByWallId.set(wall.id, hitboxMesh);
}

function buildRoomFloor(room) {
  if (!room.points || room.points.length < 3) return;

  const shape = new THREE.Shape();
  shape.moveTo(room.points[0].x, room.points[0].y);
  for (let i = 1; i < room.points.length; i++) {
    shape.lineTo(room.points[i].x, room.points[i].y);
  }
  shape.closePath();

  const geometry = new THREE.ShapeGeometry(shape);
  // ShapeGeometry is built in the XY plane; rotate flat onto the XZ ground
  // plane so RoomScene's 2D y maps to three.js z the same way walls do
  // (buildWall uses midZ = wall.start.y/end.y directly, no sign flip) —
  // rotateX(-PI/2) would mirror it onto z=-y instead, landing the floor on
  // the opposite side of the room from its walls.
  geometry.rotateX(Math.PI / 2);

  const material = new THREE.MeshStandardMaterial({
    color: 0x9c8b73,
    side: THREE.DoubleSide,
  });

  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.y = floorLayerCounter * 0.0015;
  floorLayerCounter += 1;
  mesh.userData = { kind: 'floor', roomId: room.id };
  roomGroup.add(mesh);
  floorMeshesByRoomId.set(room.id, mesh);
}

function itemColorForCatalogId(catalogItemId) {
  // Deterministic placeholder color until real glTF models load (Faza 2) —
  // same catalog item always renders the same color so users can tell items
  // apart in the scene before real thumbnails/models exist.
  let hash = 0;
  for (let i = 0; i < catalogItemId.length; i++) {
    hash = (hash * 31 + catalogItemId.charCodeAt(i)) >>> 0;
  }
  return new THREE.Color(`hsl(${hash % 360}, 55%, 55%)`);
}

// Lamps as real light sources (FINAL_VISION.md §7.5) — `item.is_light` is a
// bridge-only hint tagged on by RoomSceneActions._itemJsonForViewer/
// floorViewerPayload (Flutter looks up the catalog category; scene.js has no
// catalog access of its own). Capped well under WebGL's practical ceiling
// for simultaneous dynamic lights (~8-16 before a real deferred-rendering
// redesign would be needed) — a scene past the cap just renders those
// extra "lamps" as normal, non-emitting furniture rather than degrading
// every light already in the scene.
const MAX_DYNAMIC_LIGHTS = 12;
let activeDynamicLightCount = 0;

// Real glTF furniture models (FINAL_VISION.md/Faza 2's curated CC0 starter
// catalog — see furniture_catalog/lib/data/dev_catalog.dart) load through
// this single shared loader. `item.glb_url` is bridge-only (see
// `RoomSceneActions._itemJsonForViewer`) — scene.js itself never touches
// furniture_catalog, it only ever sees a path or nothing.
const gltfLoader = new GLTFLoader();

function buildItem(item) {
  const size = DEFAULT_ITEM_SIZE; // still the hitbox/footprint size even for real models — see loadGltfModelForItem
  const geometry = new THREE.BoxGeometry(size.widthM, size.heightM, size.depthM);
  const material = new THREE.MeshStandardMaterial({
    color: itemColorForCatalogId(item.catalog_item_id),
  });

  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.set(item.position.x, (item.position.z || 0) + size.heightM / 2, item.position.y);
  mesh.rotation.y = -(item.rotation_deg || 0) * (Math.PI / 180);
  mesh.scale.setScalar(item.scale || 1);
  mesh.userData = { kind: 'item', itemId: item.id, roomId: item.room_id, depthM: size.depthM };

  // Front-facing indicator — a dark strip on the local -Z face (see
  // applyWallSnap: items snap back-to-wall, front = local -Z, facing into
  // the room). Hidden once a real glTF model loads (see
  // loadGltfModelForItem) — the model shows its own orientation instead.
  const frontIndicator = new THREE.Mesh(
    new THREE.BoxGeometry(size.widthM * 0.7, size.heightM * 0.08, 0.02),
    new THREE.MeshStandardMaterial({ color: 0x1a1a1a }),
  );
  frontIndicator.position.set(0, -size.heightM / 2 + size.heightM * 0.08, -size.depthM / 2 - 0.005);
  mesh.add(frontIndicator);
  mesh.userData.frontIndicator = frontIndicator;

  if (item.is_light && activeDynamicLightCount < MAX_DYNAMIC_LIGHTS) {
    // No castShadow — point-light shadows need a cube map (6 render passes
    // each), a real cost this feature doesn't need to pay for "does the
    // room look lit," matching the project's explicit non-photoreal scope.
    const pointLight = new THREE.PointLight(0xfff2d0, 1.2, 5, 2);
    pointLight.position.set(0, size.heightM * 0.3, 0);
    mesh.add(pointLight);
    mesh.userData.hasLight = true;
    activeDynamicLightCount += 1;
  }

  if (item.glb_url) loadGltfModelForItem(mesh, item.glb_url, size);

  roomGroup.add(mesh);
  itemMeshesById.set(item.id, mesh);
  applyWallSnap(mesh);
}

// Loads a real glTF model as a child of the item's existing box `mesh` —
// deliberately NOT a replacement for the box. The box stays the raycast/
// hitbox target (`itemMeshesById` already points at it, drag/selection/
// wall-snap/arrow-nudge all operate on it unchanged) and the model is
// purely a visual overlay, hidden behind it until loaded. Auto-fits the
// model into `boxSize` (uniform scale, so proportions aren't squashed) and
// re-centers it on its own bounding box, since the catalog doesn't carry
// per-item real dimensions yet (Faza 2's dev catalog still shares one
// placeholder footprint for every category) — see dev_catalog.dart.
function loadGltfModelForItem(mesh, glbUrl, boxSize) {
  gltfLoader.load(
    glbUrl,
    (gltf) => {
      // `mesh` may have been removed from the scene (item deleted, floor
      // switched) by the time an in-flight load resolves — check it's
      // still the live mesh for this item before touching it.
      if (!mesh.parent) return;

      const model = gltf.scene;
      const bbox = new THREE.Box3().setFromObject(model);
      const modelSize = bbox.getSize(new THREE.Vector3());
      const center = bbox.getCenter(new THREE.Vector3());

      const scale = Math.min(
        modelSize.x > 0.0001 ? boxSize.widthM / modelSize.x : 1,
        modelSize.y > 0.0001 ? boxSize.heightM / modelSize.y : 1,
        modelSize.z > 0.0001 ? boxSize.depthM / modelSize.z : 1,
      );

      model.position.sub(center);
      model.scale.setScalar(scale);
      model.position.multiplyScalar(scale);
      model.position.y += (boxSize.heightM / 2);

      model.traverse((node) => {
        if (node.isMesh) {
          node.castShadow = true;
          node.receiveShadow = true;
        }
      });

      mesh.add(model);
      mesh.material.visible = false;
      if (mesh.userData.frontIndicator) mesh.userData.frontIndicator.visible = false;
      mesh.userData.glbLoaded = true;
    },
    undefined,
    (error) => {
      // Non-fatal — the box placeholder stays visible/interactive exactly
      // as before, so a missing/broken model degrades gracefully instead of
      // surfacing a disruptive SnackBar for what's still a fully usable
      // (if plain-colored) placed item.
      console.warn('room_3d: glTF load failed for', glbUrl, error);
    },
  );
}

// A schematic stacked-block staircase from `stair.start` rising to
// `stair.end` at `riseM` (the floor's storyHeightM — FINAL_VISION.md §6's
// "rendered stairs", connecting up to whatever sits above). Each step is a
// solid box up to its own top, so the silhouette reads as a staircase from
// the side without needing real tread/riser modeling — deliberately as
// schematic as `buildAdjacentFloorLayer`'s dimmed walls, not a CAD-accurate
// structure. `dim` renders it with the same translucent MeshBasicMaterial
// adjacent floors use, so a stair drawn on a floor shown as a dimmed
// neighbor (its top naturally lands at y=0 of whichever floor is active,
// since the stair's own Y range is [0, riseM] and adjacent floors are
// offset by exactly their own storyHeightM) looks consistent with the rest
// of that passive layer.
function buildStairGroup(stair, riseM, dim) {
  const dx = stair.end.x - stair.start.x;
  const dz = stair.end.y - stair.start.y;
  const length = Math.sqrt(dx * dx + dz * dz);
  if (length <= 0.001) return null;

  const angle = Math.atan2(dz, dx);
  const width = stair.width_m || DEFAULT_STAIR_WIDTH_M;
  const stepCount = Math.max(4, Math.round(riseM / STAIR_STEP_RISE_M));
  const stepDepth = length / stepCount;
  const stepRise = riseM / stepCount;

  const material = dim
    ? new THREE.MeshBasicMaterial({
        color: ADJACENT_FLOOR_COLOR,
        transparent: true,
        opacity: ADJACENT_FLOOR_OPACITY,
        depthWrite: false,
      })
    : new THREE.MeshStandardMaterial({ color: STAIR_COLOR });

  const group = new THREE.Group();
  for (let i = 0; i < stepCount; i++) {
    const stepHeight = stepRise * (i + 1);
    const geometry = new THREE.BoxGeometry(stepDepth, stepHeight, width);
    const mesh = new THREE.Mesh(geometry, material);
    mesh.position.set(-length / 2 + stepDepth * (i + 0.5), stepHeight / 2, 0);
    group.add(mesh);
  }

  group.position.set((stair.start.x + stair.end.x) / 2, 0, (stair.start.y + stair.end.y) / 2);
  group.rotation.y = -angle;
  return group;
}

function loadScene(data) {
  clearRoomGroup();

  const openingsByWallId = new Map();
  (data.openings || []).forEach((opening) => {
    const list = openingsByWallId.get(opening.wall_id) || [];
    list.push(opening);
    openingsByWallId.set(opening.wall_id, list);
  });

  (data.walls || []).forEach((wall) => buildWall(wall, openingsByWallId.get(wall.id)));
  computeWallOutwardNormals();
  (data.rooms || []).forEach(buildRoomFloor);
  (data.items || []).forEach(buildItem);
  (data.stairs || []).forEach((stair) => {
    const group = buildStairGroup(stair, data.story_height_m || DEFAULT_STORY_HEIGHT_M, false);
    if (group) roomGroup.add(group);
  });

  // RoomScene only persists materialId, not the color/texture it maps to
  // (that lookup lives in the Flutter-side surface_materials catalog) — so
  // restored zones render in a neutral color until re-tinted via
  // setWallZoneMaterial/previewMaterial. Known limitation, see
  // docs/sims_mode/IMPLEMENTATION_CHECKLIST.md.
  (data.wall_surface_zones || []).forEach((zone) =>
    getOrCreateWallZoneMesh({
      wall_id: zone.wall_id,
      zone_id: zone.id,
      height_range: zone.height_range,
      position_range: zone.position_range,
    }),
  );

  applyShadowFlags(); // no-op unless presentation mode is already on

  // Adjacent floors (FINAL_VISION.md §6's true stacking) arrive bundled in
  // THIS SAME payload — clearRoomGroup already cleared the old ones above,
  // rebuild fresh from whatever Flutter decided should show (null for
  // either/both if there's no floor there, or if the "sąsiednie piętra"
  // toggle is off).
  ['below', 'above'].forEach((key) => {
    if (!data[key]) return;
    const layer = buildAdjacentFloorLayer(data[key], data[key].y_offset || 0);
    adjacentFloorGroups[key] = layer;
    scene.add(layer);
  });

  post('sceneLoaded', {});
}

// ---------------------------------------------------------------------------
// Incremental mutations (mirror room_scene_actions.dart 1:1)
// ---------------------------------------------------------------------------

function placeItem(item) {
  buildItem(item);
  applyShadowFlags();
}

function moveItem(payload) {
  const mesh = itemMeshesById.get(payload.id);
  if (!mesh) return;

  if (payload.position) {
    mesh.position.set(
      payload.position.x,
      (payload.position.z || 0) + DEFAULT_ITEM_SIZE.heightM / 2,
      payload.position.y,
    );
  }
  if (typeof payload.rotation_deg === 'number') {
    mesh.rotation.y = -payload.rotation_deg * (Math.PI / 180);
  }
  if (typeof payload.scale === 'number') {
    mesh.scale.setScalar(payload.scale);
  }
}

function removeItem(payload) {
  const mesh = itemMeshesById.get(payload.id);
  if (!mesh) return;

  if (mesh.userData.hasLight) activeDynamicLightCount -= 1;
  roomGroup.remove(mesh);
  disposeObject(mesh);
  itemMeshesById.delete(payload.id);
  if (selectedItemId === payload.id) selectedItemId = null;
}

function addWall(wall) {
  buildWall(wall);
  // A new wall shifts the room's centroid/shape, so every wall's cached
  // outward normal (used by the cutaway system) needs recomputing — same
  // call loadScene already makes after building the initial wall set.
  computeWallOutwardNormals();
  applyShadowFlags();
}

function addRoom(room) {
  buildRoomFloor(room);
  applyShadowFlags();
}

function removeWall(payload) {
  const wallId = payload.wall_id;
  const wallGroup = wallDefaultMaterialMeshesByWallId.get(wallId);
  if (wallGroup) {
    roomGroup.remove(wallGroup);
    disposeObject(wallGroup); // also disposes any wall-zone children parented to it
  }

  const hitboxMesh = wallHitboxMeshesByWallId.get(wallId);
  if (hitboxMesh) {
    roomGroup.remove(hitboxMesh);
    disposeObject(hitboxMesh);
  }

  wallDefaultMaterialMeshesByWallId.delete(wallId);
  wallHitboxMeshesByWallId.delete(wallId);
  wallSegmentsById.delete(wallId);

  // Zone map entries for this wall now point at disposed meshes — drop them
  // rather than leave stale references (disposeObject already freed their
  // geometry/material as children of the wall group above).
  [...wallZoneMeshesByZoneId.entries()].forEach(([zoneId, zoneMesh]) => {
    if (zoneMesh.userData.wallId === wallId) wallZoneMeshesByZoneId.delete(zoneId);
  });

  if (selectedWallId === wallId) {
    selectedWallId = null;
    clearWallEndpointHandles();
  }

  // Removing a wall changes the room's shape/centroid just like adding one
  // does — every remaining wall's cached outward normal needs recomputing.
  computeWallOutwardNormals();
}

function removeRoom(payload) {
  const roomId = payload.room_id;
  const floorMesh = floorMeshesByRoomId.get(roomId);
  if (floorMesh) {
    roomGroup.remove(floorMesh);
    disposeObject(floorMesh);
  }
  floorMeshesByRoomId.delete(roomId);
  if (selectedRoomId === roomId) selectedRoomId = null;
}

// Mutates an existing wall's box geometry (visual + hitbox) in place rather
// than removing/rebuilding the mesh, so its face-material array (front/back
// tint) and any wall-zone children stay attached — see
// RoomSceneActions.setWallThickness's doc comment for the one rough edge
// (zone position doesn't retroactively recenter around the new thickness).
function updateWallThickness(payload) {
  const wallId = payload.wall_id;
  const thicknessM = payload.thickness_m;
  const wallGroup = wallDefaultMaterialMeshesByWallId.get(wallId);
  const seg = wallSegmentsById.get(wallId);
  if (!wallGroup || !seg || !(thicknessM > 0)) return;

  // Each segment keeps its own width/height (thickness change never affects
  // those, only the Z depth) — reuse them rather than recomputing rects.
  wallGroup.children.forEach((segment) => {
    if (segment.userData.kind !== 'wallSegment') return;
    const { width, height } = segment.geometry.parameters;
    segment.geometry.dispose();
    segment.geometry = new THREE.BoxGeometry(width, height, thicknessM);
  });
  wallGroup.userData.thicknessM = thicknessM;

  const hitboxMesh = wallHitboxMeshesByWallId.get(wallId);
  if (hitboxMesh) {
    const { width, height } = hitboxMesh.geometry.parameters;
    hitboxMesh.geometry.dispose();
    hitboxMesh.geometry = new THREE.BoxGeometry(width, height, thicknessM);
  }

  seg.halfThickness = thicknessM / 2;
}

function applyMaterialTint(target, color) {
  // No real texture pipeline yet — color is the only rendering hint we
  // currently pass over the bridge. Real texture_url loading lands with
  // the surface_materials catalog integration (Faza 2).
  if (!target || !color) return;

  // A wall is now a Group of segment meshes (see buildWall, split around
  // any door/window openings) — tint every segment's front face so an
  // opening doesn't leave part of the wall a different color. The
  // Array.isArray guard already skips non-wall children added to the same
  // group (e.g. wall-zone overlays, which use one plain material).
  if (target.isGroup) {
    target.children.forEach((segment) => {
      if (Array.isArray(segment.material)) segment.material[WALL_FRONT_MATERIAL_INDEX].color.set(color);
    });
    return;
  }

  // Wall meshes carry a 6-material array (one per box face) so the two
  // room-facing sides can differ; floor/zone meshes still use one plain
  // material. Only the "front" face (see WALL_FRONT_MATERIAL_INDEX) gets
  // tinted for a wall — the back face is left at its built-in default so
  // the two sides of a wall stop rendering identically.
  if (Array.isArray(target.material)) {
    target.material[WALL_FRONT_MATERIAL_INDEX].color.set(color);
  } else {
    target.material.color.set(color);
  }
}

// A wall zone is rendered as a thin overlay box, CHILD of the wall mesh, so
// it inherits the wall's position/rotation for free. BoxGeometry(length,
// height, thickness) puts length along local X, height along local Y,
// thickness along local Z — so a zone's local X/Y offset from the wall
// center is just (positionRange/heightRange midpoint - 0.5) * wall size,
// and it sits proud of the wall's front face along local Z.
function getOrCreateWallZoneMesh(payload) {
  const existing = wallZoneMeshesByZoneId.get(payload.zone_id);
  if (existing) return existing;

  const wallGroup = wallDefaultMaterialMeshesByWallId.get(payload.wall_id);
  if (!wallGroup) return null;

  // Wall dimensions now come from the group's userData, not
  // geometry.parameters — a wall Group has no geometry of its own (see
  // buildWall), and even for a single-segment wall the segment's own
  // geometry is the corner-fill-extended size, not the true dimensions.
  const { trueLengthM: wallLength, baseHeightM: wallHeight, thicknessM: wallThickness } = wallGroup.userData;

  const [h0, h1] = payload.height_range || [0, 1];
  const [p0, p1] = payload.position_range || [0, 1];

  const zoneWidth = Math.max(0.01, (p1 - p0) * wallLength);
  const zoneHeight = Math.max(0.01, (h1 - h0) * wallHeight);

  const geometry = new THREE.BoxGeometry(zoneWidth, zoneHeight, 0.01);
  // Default to the wall's current FRONT-face color so an uncolored zone
  // (e.g. restored from RoomScene without a color hint) blends in rather
  // than flashing white — zones always sit on the front face (see the
  // local Z offset below), so match that face specifically. Any segment's
  // front material works as the color source since they're all built with
  // the same materialOpts.
  const referenceSegment = wallGroup.children.find((child) => Array.isArray(child.material));
  const material = new THREE.MeshStandardMaterial({
    color: referenceSegment
      ? referenceSegment.material[WALL_FRONT_MATERIAL_INDEX].color.clone()
      : 0xd9d3c7,
  });
  const mesh = new THREE.Mesh(geometry, material);

  const localX = (p0 + p1) / 2 * wallLength - wallLength / 2;
  // The group sits at floor level (position.y = 0, see buildWall) with
  // segments positioned at their own ABSOLUTE height — so a zone's local Y
  // relative to the group is just its absolute center height, no longer
  // "- wallHeight / 2" (that centered-box convention only applied to the
  // old single-mesh wall).
  const localY = (h0 + h1) / 2 * wallHeight;
  mesh.position.set(localX, localY, wallThickness / 2 + 0.006);
  mesh.userData = { kind: 'wallZone', zoneId: payload.zone_id, wallId: payload.wall_id };

  wallGroup.add(mesh);
  wallZoneMeshesByZoneId.set(payload.zone_id, mesh);
  return mesh;
}

function setWallZoneMaterial(payload) {
  const mesh = getOrCreateWallZoneMesh(payload);
  applyMaterialTint(mesh, payload.color);
}

function setWholeWallMaterial(payload) {
  applyMaterialTint(wallDefaultMaterialMeshesByWallId.get(payload.wall_id), payload.color);
}

function setFloorMaterial(payload) {
  applyMaterialTint(floorMeshesByRoomId.get(payload.room_id), payload.color);
}

function previewMaterial(payload) {
  // Preview reuses the same zone (or whole-wall) mesh a subsequent
  // setWallZoneMaterial/setWholeWallMaterial call would target, since the
  // Flutter-side picker always resolves the same deterministic zone_id for
  // a given wall+preset — so there's no orphaned "preview-only" mesh left
  // behind if the user never commits.
  if (payload.zone_id) {
    applyMaterialTint(getOrCreateWallZoneMesh(payload), payload.color);
  } else if (payload.wall_id) {
    applyMaterialTint(wallDefaultMaterialMeshesByWallId.get(payload.wall_id), payload.color);
  }
}

// "Zrzut ekranu" (FINAL_VISION.md §7.4 — flagged as the simplest export item,
// worth doing first). A fresh `render()` immediately followed by
// `toDataURL()` in the same synchronous tick is the standard way to grab a
// WebGL canvas without needing `preserveDrawingBuffer: true` on the
// renderer (that flag exists for capturing an OLD frame after the browser
// may have already cleared the buffer between animation frames — not
// needed here since we render-then-capture back to back).
function captureScreenshot() {
  renderer.render(scene, camera);
  const dataUrl = renderer.domElement.toDataURL('image/png');
  post('screenshotCaptured', { data_url: dataUrl });
}

// Top-down technical plan (FINAL_VISION.md §7.4's "rzut z góry z wymiarami"
// — connects to §7.1's dimension labels, but those are an HTML `<div>`
// overlay that never shows up in `toDataURL()`'s captured WebGL pixels, so
// this composites its own text pass onto a 2D canvas instead of reusing
// `updateDimensionLabels`. Reuses `minimapCamera`/`fitMinimapCameraToScene`
// (already an orthographic camera fitted to the whole plan) rather than a
// dedicated camera — the minimap's existing frustum-fitting math is exactly
// what a full-frame top-down shot needs too, just rendered at full canvas
// size instead of scissored into the corner.
function captureTopDownPlan() {
  if (!minimapCamera || wallSegmentsById.size === 0) {
    post('error', { message: 'Brak geometrii do wyeksportowania planu.' });
    return;
  }

  const originalCamera = camera;
  fitMinimapCameraToScene();
  camera = minimapCamera;
  renderer.render(scene, minimapCamera);

  const canvas = renderer.domElement;
  const composite = document.createElement('canvas');
  composite.width = canvas.width;
  composite.height = canvas.height;
  const ctx = composite.getContext('2d');
  ctx.drawImage(canvas, 0, 0);

  // Same dark-pill-with-light-green-text look as the live "Wymiary" overlay
  // (index.html's `.dimension-label` CSS) rather than a plain dark-on-light
  // scheme — the rendered scene's own background (`0x1a1a1f`) is dark, so a
  // dark fill color would be nearly invisible; matching the live style also
  // keeps this export visually consistent with what "Wymiary" already looks
  // like on screen.
  const fontPx = Math.round(16 * renderer.getPixelRatio());
  ctx.font = `600 ${fontPx}px sans-serif`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';

  wallSegmentsById.forEach((seg) => {
    const dx = seg.x2 - seg.x1;
    const dz = seg.z2 - seg.z1;
    const length = Math.hypot(dx, dz);
    if (length <= 0.001) return;

    const midWorld = new THREE.Vector3((seg.x1 + seg.x2) / 2, 0, (seg.z1 + seg.z2) / 2);
    const ndc = midWorld.project(minimapCamera);
    const x = (ndc.x * 0.5 + 0.5) * canvas.width;
    const y = (-ndc.y * 0.5 + 0.5) * canvas.height;

    const text = `${length.toFixed(2)} m`;
    const paddingX = 6 * renderer.getPixelRatio();
    const paddingY = 4 * renderer.getPixelRatio();
    const metrics = ctx.measureText(text);
    const pillWidth = metrics.width + paddingX * 2;
    const pillHeight = fontPx + paddingY * 2;

    ctx.fillStyle = 'rgba(20, 20, 26, 0.75)';
    ctx.beginPath();
    ctx.roundRect(x - pillWidth / 2, y - pillHeight / 2, pillWidth, pillHeight, 5 * renderer.getPixelRatio());
    ctx.fill();

    ctx.fillStyle = '#a8e6a3';
    ctx.fillText(text, x, y);
  });

  const dataUrl = composite.toDataURL('image/png');

  // Restore the live perspective view before returning — otherwise the next
  // animate() tick would still render correctly (it always renders with
  // `camera`), but a caller inspecting the canvas synchronously right after
  // this call would see the top-down frame.
  camera = originalCamera;
  renderer.render(scene, originalCamera);

  post('topDownPlanCaptured', { data_url: dataUrl });
}

// Eksport glTF/OBJ (FINAL_VISION.md §7.4 — explicitly the lowest-priority
// export item in that doc, "niche need"; still cheap enough to do once
// screenshot/PDF-plan are ahead of it). Exports `roomGroup` (the active
// floor's walls/floors/items) as a single binary .glb — NOT the whole
// `scene`, which also holds the axis gizmo/minimap dummy geometry and the
// walk-mode indicator that have nothing to do with the room itself.
// GLTFExporter/its TextureUtils.js dependency are vendored flat alongside
// three.module.min.js/OrbitControls.js, same convention, same source
// (unpkg, matching the r160 three.js build already in this folder).
function captureGltfExport() {
  const exporter = new GLTFExporter();
  exporter.parse(
    roomGroup,
    (result) => {
      // `binary: true` gives an ArrayBuffer (a .glb) rather than a JSON
      // object (a .gltf) — one self-contained file, no separate .bin/
      // texture siblings for Flutter to juggle when saving.
      const bytes = new Uint8Array(result);
      let binary = '';
      for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
      post('gltfExportReady', { base64: btoa(binary) });
    },
    (error) => {
      post('error', { message: `Eksport glTF nie powiódł się: ${(error && error.message) || error}` });
    },
    { binary: true },
  );
}

// Which mesh kinds (see the various `userData.kind` tags set at creation —
// 'wallSegment'/'floor'/'item'/'wallZone') participate in shadows, and how.
// Floor/wallZone are thin, ground-hugging overlays — receiving only avoids
// self-shadowing artifacts a flat surface "casting" onto itself would cause.
const PRESENTATION_CAST_KINDS = new Set(['wallSegment', 'item']);
const PRESENTATION_RECEIVE_KINDS = new Set(['wallSegment', 'floor', 'item', 'wallZone']);

function applyShadowFlags() {
  scene.traverse((obj) => {
    if (!obj.isMesh) return;
    const kind = obj.userData && obj.userData.kind;
    if (PRESENTATION_CAST_KINDS.has(kind)) obj.castShadow = presentationModeEnabled;
    if (PRESENTATION_RECEIVE_KINDS.has(kind)) obj.receiveShadow = presentationModeEnabled;
  });
}

function setPresentationModeEnabled(enabled) {
  presentationModeEnabled = enabled;

  renderer.shadowMap.enabled = enabled;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;

  sunLight.castShadow = enabled;
  // Dimmer flat ambient + a bit more directional contrast + a warm/cool fill
  // reads as "staged photo" rather than the working mode's uniform flatness.
  ambientLight.intensity = enabled ? 0.35 : 0.65;
  sunLight.intensity = enabled ? 1.15 : 0.9;
  presentationFillLight.intensity = enabled ? 0.45 : 0;

  applyShadowFlags();
}

function setCameraPreset(preset) {
  if (preset === 'topDown') {
    animateCameraTo(new THREE.Vector3(0, 12, 0.001), new THREE.Vector3(0, 0, 0));
  } else if (preset === 'reset' || preset === 'orbit') {
    animateCameraTo(new THREE.Vector3(6, 5, 6), new THREE.Vector3(0, 1, 0));
  }
}

// Selection highlight: a soft, translucent outline halo rather than tinting
// the object's own surface material (the earlier flat emissive tint read as
// a harsh color wash over whatever material/color was already there).
// Implemented as a slightly-inflated clone of the same geometry, rendered
// BackSide (or DoubleSide for the flat floor shape, which has no "inside" to
// view from) so it reads as a thin glowing rim around the selected object's
// silhouette instead of recoloring it. Parented to the target mesh so it
// tracks position/rotation — and, for a wall being cutaway-shrunk, its
// current scale — for free; disposed automatically by the existing
// disposeObject(mesh) traversal in clearRoomGroup/removeItem, since it's
// just another child.
const SELECTION_OUTLINE_COLOR = 0xffd166;
const SELECTION_OUTLINE_OPACITY = 0.75;

function attachSelectionOutline(mesh, { inflate = 1.06, doubleSided = false, yOffset = 0, geometry } = {}) {
  if (mesh.userData.selectionOutline) return;

  // `geometry`, when passed explicitly, is for a wall (a Group, with no
  // single geometry of its own to clone) — a synthetic full bounding box
  // ignoring any door/window opening, same simplification as the wall's
  // click hitbox: a pixel-perfect per-segment outline isn't worth the
  // extra complexity for a highlight ring.
  const outline = new THREE.Mesh(
    geometry || mesh.geometry.clone(),
    new THREE.MeshBasicMaterial({
      color: SELECTION_OUTLINE_COLOR,
      transparent: true,
      opacity: SELECTION_OUTLINE_OPACITY,
      side: doubleSided ? THREE.DoubleSide : THREE.BackSide,
      depthWrite: false,
    }),
  );
  outline.scale.setScalar(inflate);
  outline.position.y = yOffset;
  mesh.add(outline);
  mesh.userData.selectionOutline = outline;
}

function detachSelectionOutline(mesh) {
  const outline = mesh && mesh.userData && mesh.userData.selectionOutline;
  if (!outline) return;

  mesh.remove(outline);
  outline.geometry.dispose();
  outline.material.dispose();
  mesh.userData.selectionOutline = null;
}

function setSelection(id) {
  selectedItemId = id || null;
  itemMeshesById.forEach((mesh, itemId) => {
    if (itemId === selectedItemId) attachSelectionOutline(mesh, { inflate: 1.08 });
    else detachSelectionOutline(mesh);
  });
}

// Wall/floor selection highlight is purely a local viewer concern (like the
// item highlight above) — set immediately on click, alongside the
// zoneSelected/roomSelected bridge post that tells Flutter which id to
// target with the next material change.
function selectWall(wallId) {
  selectedWallId = wallId || null;
  // A pending "place a door/window here" click is scoped to whichever wall
  // was selected when the placing toggle was switched on — selecting a
  // different wall (or deselecting) invalidates it defensively, since
  // WallMaterialPanel's own placing-toggle state is keyed to the selected
  // wall and would otherwise desync from this.
  placingOpeningKind = null;
  wallDefaultMaterialMeshesByWallId.forEach((wallGroup, id) => {
    if (id !== selectedWallId) {
      detachSelectionOutline(wallGroup);
      return;
    }

    // A wall is a Group (see buildWall), positioned at floor level with its
    // segments at their own absolute height — so the outline's synthetic
    // full-bounding-box geometry needs an explicit yOffset of half the
    // wall's height to sit centered on the wall, unlike items/floor which
    // clone their own mesh's (already-centered) geometry directly.
    const { trueLengthM, baseHeightM, thicknessM } = wallGroup.userData;
    attachSelectionOutline(wallGroup, {
      inflate: 1.08,
      yOffset: baseHeightM / 2,
      geometry: new THREE.BoxGeometry(trueLengthM + thicknessM, baseHeightM, thicknessM),
    });
  });
  rebuildWallEndpointHandles();
}

function clearWallEndpointHandles() {
  if (!wallEndpointHandlesGroup) return;
  while (wallEndpointHandlesGroup.children.length) {
    disposeObject(wallEndpointHandlesGroup.children.pop());
  }
}

// Two small draggable spheres at the selected wall's endpoints — see
// wallEndpointDragState's doc comment for why dragging one is a preview-only
// interaction, not a live geometry edit.
function rebuildWallEndpointHandles() {
  clearWallEndpointHandles();
  if (!selectedWallId) return;

  const seg = wallSegmentsById.get(selectedWallId);
  if (!seg) return;

  [['start', seg.x1, seg.z1], ['end', seg.x2, seg.z2]].forEach(([endpoint, x, z]) => {
    const handle = new THREE.Mesh(
      new THREE.SphereGeometry(WALL_ENDPOINT_HANDLE_RADIUS_M, 16, 16),
      new THREE.MeshBasicMaterial({ color: WALL_ENDPOINT_HANDLE_COLOR }),
    );
    handle.position.set(x, 0.11, z);
    handle.userData = { kind: 'wallEndpointHandle', wallId: selectedWallId, endpoint };
    wallEndpointHandlesGroup.add(handle);
  });
}

function selectFloor(roomId) {
  selectedRoomId = roomId || null;
  floorMeshesByRoomId.forEach((mesh, id) => {
    // Floor is a flat ShapeGeometry — a BackSide outline is invisible from
    // above (there's no "inside" to it), so use DoubleSide and nudge it
    // just under the floor's own surface so it peeks out as a border
    // around the edges instead of z-fighting with it.
    if (id === selectedRoomId) attachSelectionOutline(mesh, { inflate: 1.06, doubleSided: true, yOffset: -0.0008 });
    else detachSelectionOutline(mesh);
  });
}

// ---------------------------------------------------------------------------
// Pointer interaction: empty-space drag orbits the camera (OrbitControls
// handles that natively); a drag started on a selected item moves it
// instead — see docs/sims_mode/ARCHITECTURE.md section 5.
// ---------------------------------------------------------------------------

const raycaster = new THREE.Raycaster();
const pointerNdc = new THREE.Vector2();
const floorPlane = new THREE.Plane(new THREE.Vector3(0, 1, 0), 0);

function updatePointerNdc(event) {
  const rect = renderer.domElement.getBoundingClientRect();
  pointerNdc.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
  pointerNdc.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
}

function pickItemAt(event) {
  updatePointerNdc(event);
  raycaster.setFromCamera(pointerNdc, camera);
  const hits = raycaster.intersectObjects([...itemMeshesById.values()]);
  return hits.length ? hits[0].object.userData.itemId : null;
}

// ---------------------------------------------------------------------------
// Build mode: draw a new wall or a new virtual room polygon by clicking
// points on the floor plane. A wall commits itself the moment its 2nd point
// lands (post('wallDrawn', ...), Flutter turns that into a real
// RoomSceneActions.addWall call, which comes back as an 'addWall' command —
// see the incremental-mutation section below). A room polygon accumulates
// points until Flutter explicitly sends 'finishRoomDraw' (a button in its
// side panel, since "how many points is enough" is the user's call, not
// something a click count can decide on its own).
// ---------------------------------------------------------------------------

const BUILD_SNAP_DISTANCE_M = 0.25;
const BUILD_MARKER_COLOR = 0xffcc00;
const BUILD_GUIDE_COLOR = 0x4fd1ff;
const BUILD_GUIDE_HALF_LENGTH_M = 30;
const BUILD_GUIDE_ALIGN_TOLERANCE_M = 0.03;

function setBuildMode(mode, isVirtual, thicknessM) {
  buildMode = mode === 'wall' || mode === 'room' || mode === 'stair' ? mode : null;
  buildIsVirtual = !!isVirtual;
  if (typeof thicknessM === 'number' && thicknessM > 0) buildThicknessM = thicknessM;
  buildPoints = [];
  clearBuildPreview();
  // OrbitControls has its own independent pointerdown listener on the same
  // canvas element — without this, clicking to place a build point ALSO
  // starts an orbit-rotate drag (LEFT button does both), which is exactly
  // the "the view moves when I click to place a wall" bug. Placing points
  // is the only thing the mouse does while building; camera navigation
  // resumes the moment build mode is left (Escape/V/S/switching tools).
  controls.enabled = !buildMode;
}

function setPlacingOpening(kind) {
  placingOpeningKind = kind === 'door' || kind === 'window' ? kind : null;
}

function clearAdjacentFloorGroups() {
  ['below', 'above'].forEach((key) => {
    if (!adjacentFloorGroups[key]) return;
    scene.remove(adjacentFloorGroups[key]);
    disposeObject(adjacentFloorGroups[key]);
    adjacentFloorGroups[key] = null;
  });
}

// Builds one dimmed, non-interactive adjacent floor (below or above the
// active one) from the SAME flat floor data shape the active floor itself
// uses. Reuses `computeWallSolidRects`/`extendOuterEdgesForCornerFill`
// (already pure functions with no side effects on the interactive maps)
// for real door/window cutouts — an adjacent floor's walls look honestly
// cut, not solid boxes, even though nothing about them is clickable/
// selectable/draggable the way the active floor's own geometry is.
// Deliberately simpler than buildWall/buildRoomFloor/buildItem: no corner-
// fill's full material-index tinting, no wall zones, no selection outlines,
// no per-item front indicators — this is passive spatial context, not an
// editable layer, so it doesn't need any of that.
function buildAdjacentFloorLayer(floorData, yOffset) {
  const group = new THREE.Group();
  group.position.y = yOffset;

  const dimMaterialOpts = {
    color: ADJACENT_FLOOR_COLOR,
    transparent: true,
    opacity: ADJACENT_FLOOR_OPACITY,
    depthWrite: false,
  };

  const openingsByWallId = new Map();
  (floorData.openings || []).forEach((opening) => {
    const list = openingsByWallId.get(opening.wall_id) || [];
    list.push(opening);
    openingsByWallId.set(opening.wall_id, list);
  });

  (floorData.walls || []).forEach((wall) => {
    const { length, angle } = wallVector(wall);
    if (length <= 0.001) return;

    const thickness = wall.thickness_m || 0.15;
    const height = wall.height_m || 2.6;
    const rects = computeWallSolidRects(openingsByWallId.get(wall.id), length, height);
    extendOuterEdgesForCornerFill(rects, length, thickness);

    const wallGroup = new THREE.Group();
    rects.forEach((rect) => {
      const geometry = new THREE.BoxGeometry(rect.xEnd - rect.xStart, rect.yEnd - rect.yStart, thickness);
      const mesh = new THREE.Mesh(geometry, new THREE.MeshBasicMaterial(dimMaterialOpts));
      mesh.position.set((rect.xStart + rect.xEnd) / 2, (rect.yStart + rect.yEnd) / 2, 0);
      wallGroup.add(mesh);
    });

    wallGroup.position.set((wall.start.x + wall.end.x) / 2, 0, (wall.start.y + wall.end.y) / 2);
    wallGroup.rotation.y = -angle;
    group.add(wallGroup);
  });

  (floorData.rooms || []).forEach((room) => {
    if (!room.points || room.points.length < 3) return;
    const shape = new THREE.Shape();
    shape.moveTo(room.points[0].x, room.points[0].y);
    for (let i = 1; i < room.points.length; i++) shape.lineTo(room.points[i].x, room.points[i].y);
    const geometry = new THREE.ShapeGeometry(shape);
    geometry.rotateX(Math.PI / 2);
    const mesh = new THREE.Mesh(
      geometry,
      new THREE.MeshBasicMaterial({ ...dimMaterialOpts, side: THREE.DoubleSide, opacity: ADJACENT_FLOOR_OPACITY * 0.6 }),
    );
    group.add(mesh);
  });

  (floorData.items || []).forEach((item) => {
    const size = DEFAULT_ITEM_SIZE;
    const geometry = new THREE.BoxGeometry(size.widthM, size.heightM, size.depthM);
    const mesh = new THREE.Mesh(geometry, new THREE.MeshBasicMaterial(dimMaterialOpts));
    mesh.position.set(item.position.x, (item.position.z || 0) + size.heightM / 2, item.position.y);
    mesh.rotation.y = -(item.rotation_deg || 0) * (Math.PI / 180);
    group.add(mesh);
  });

  (floorData.stairs || []).forEach((stair) => {
    const stairGroup = buildStairGroup(stair, floorData.story_height_m || DEFAULT_STORY_HEIGHT_M, true);
    if (stairGroup) group.add(stairGroup);
  });

  return group;
}

function cancelBuild() {
  buildMode = null;
  buildIsVirtual = false;
  buildPoints = [];
  clearBuildPreview();
  controls.enabled = true;
}

function clearBuildPreview() {
  if (!buildPreviewGroup) return;
  while (buildPreviewGroup.children.length) {
    disposeObject(buildPreviewGroup.children.pop());
  }
}

// Snaps to the nearest existing wall endpoint within BUILD_SNAP_DISTANCE_M
// so new walls/room corners land exactly on existing corners instead of a
// pixel off — the same tolerance concept as furniture wall-snap, just
// applied to points instead of a wall's whole centerline. Falls back to
// snapping onto the nearest wall's CENTERLINE (not just its endpoints) when
// no corner is close enough, so a new wall can start/end flush against a
// T-junction partway along another wall, not only at its corners — the
// "snap to other walls" extension of the original corner-only version.
function snapBuildPoint(x, z) {
  let bestCorner = null;
  let bestCornerDistSq = BUILD_SNAP_DISTANCE_M * BUILD_SNAP_DISTANCE_M;

  wallSegmentsById.forEach((seg) => {
    [[seg.x1, seg.z1], [seg.x2, seg.z2]].forEach(([px, pz]) => {
      const dx = px - x, dz = pz - z;
      const distSq = dx * dx + dz * dz;
      if (distSq < bestCornerDistSq) {
        bestCornerDistSq = distSq;
        bestCorner = { x: px, z: pz };
      }
    });
  });

  // `snapped` lets redrawBuildPreview show a distinct "you're on an existing
  // corner" indicator (a ring) — without it, snapping to a vertex was silent:
  // the yellow rubber-band marker looked the same whether it had snapped or
  // was just sitting at the raw cursor position, so there was no visual
  // confirmation the wall would actually start/end exactly on that corner.
  if (bestCorner) return { ...bestCorner, snapped: true };

  let bestLine = null;
  let bestLineDistSq = BUILD_SNAP_DISTANCE_M * BUILD_SNAP_DISTANCE_M;

  wallSegmentsById.forEach((seg) => {
    const info = pointToSegmentInfo(x, z, seg.x1, seg.z1, seg.x2, seg.z2);
    if (info.distSq < bestLineDistSq) {
      bestLineDistSq = info.distSq;
      bestLine = { x: info.footX, z: info.footZ };
    }
  });

  return bestLine ? { ...bestLine, snapped: true } : { x, z, snapped: false };
}

// Same idea as floor_plan's Shift-constrained axis alignment
// (floor_plan_canvas_geometry.dart's _applyShiftDrawingAlignment): holding
// Shift while placing the 2nd+ point of the current shape locks the new
// segment to whichever of horizontal/vertical (relative to the last placed
// point) the cursor is closer to, so straight walls/room edges are easy to
// place exactly. Corner snapping (snapBuildPoint) still applies on top —
// this only constrains which axis the raw point is projected onto first.
function applyBuildAxisLock(x, z) {
  if (buildPoints.length === 0) return { x, z };
  const last = buildPoints[buildPoints.length - 1];
  const dx = Math.abs(x - last.x);
  const dz = Math.abs(z - last.z);
  return dx >= dz ? { x, z: last.z } : { x: last.x, z };
}

// Ported from floor_plan_canvas_geometry.dart's _applyAngleLock — same
// "divide-round-multiply" snap on the raw atan2 angle, gated by the same
// 5° tolerance so a distant angle is left alone rather than yanked onto a
// step. Toggle + step (15/30/45/90°) are Flutter-side UI state (BuildPanel),
// sent over the bridge via setAngleLock — mirrored here only as plain
// module state, same pattern as buildIsVirtual/buildThicknessM.
let angleLockEnabled = true;
let angleStepDegrees = 90;
const ANGLE_SNAP_TOLERANCE_DEG = 5;

function angleDiffDeg(a, b) {
  const diff = Math.abs(a - b) % 360;
  return diff > 180 ? 360 - diff : diff;
}

function applyBuildAngleLock(x, z) {
  if (buildPoints.length === 0) return { x, z };
  const last = buildPoints[buildPoints.length - 1];
  const dx = x - last.x, dz = z - last.z;
  const length = Math.hypot(dx, dz);
  if (length < 0.001) return { x, z };

  const angle = Math.atan2(dz, dx);
  const stepRad = (angleStepDegrees * Math.PI) / 180;
  const snappedAngle = Math.round(angle / stepRad) * stepRad;

  if (angleDiffDeg((angle * 180) / Math.PI, (snappedAngle * 180) / Math.PI) > ANGLE_SNAP_TOLERANCE_DEG) {
    return { x, z };
  }

  return {
    x: last.x + Math.cos(snappedAngle) * length,
    z: last.z + Math.sin(snappedAngle) * length,
  };
}

// Same priority order as floor_plan's `_prepareDrawingPoint`: Shift's
// horizontal/vertical-only lock always wins when held; otherwise angle-lock
// applies if the toggle is on AND Alt isn't held (Alt is the "just this
// once, give me the free/raw angle" override, even with the toggle on).
function computeLockedBuildPoint(x, z, event) {
  if (event.shiftKey) return applyBuildAxisLock(x, z);
  if (angleLockEnabled && !event.altKey) return applyBuildAngleLock(x, z);
  return { x, z };
}

function setAngleLock(payload) {
  if (typeof payload.enabled === 'boolean') angleLockEnabled = payload.enabled;
  if (typeof payload.step_degrees === 'number' && payload.step_degrees > 0) {
    angleStepDegrees = payload.step_degrees;
  }
}

// A thin, full-length line through (fromX, fromZ) along a single axis —
// the same idea as floor_plan's alignment guides (floor_plan_canvas_geometry
// .dart's _applyShiftDrawingAlignment/_applySmartGuides): a visual reference
// showing you're lined up straight with some existing point, so you can
// draw an even wall/room edge without guessing. Now aligns to ANY existing
// wall corner or already-placed point in this draw (collectAlignmentCandidates),
// not just the immediately-previous point — matching floor_plan's own
// smart guides, which line up with any nearby corner too.
function addGuideLine(fromX, fromZ, axis) {
  const positions = axis === 'x'
    ? [fromX - BUILD_GUIDE_HALF_LENGTH_M, 0.04, fromZ, fromX + BUILD_GUIDE_HALF_LENGTH_M, 0.04, fromZ]
    : [fromX, 0.04, fromZ - BUILD_GUIDE_HALF_LENGTH_M, fromX, 0.04, fromZ + BUILD_GUIDE_HALF_LENGTH_M];

  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  const line = new THREE.Line(
    geometry,
    new THREE.LineBasicMaterial({ color: BUILD_GUIDE_COLOR, transparent: true, opacity: 0.55 }),
  );
  buildPreviewGroup.add(line);
}

// Every existing wall corner plus every point already placed this draw —
// the full pool of reference points an alignment guide can snap to. Not
// just the immediately-previous point (that was the original, simplified
// version) — floor_plan's own smart guides align to any nearby wall corner
// too, and starting a brand new wall lined up with some other wall's corner
// across the room is exactly the "snap to other walls" this extends.
function collectAlignmentCandidates() {
  const candidates = [...buildPoints];
  wallSegmentsById.forEach((seg) => {
    candidates.push({ x: seg.x1, z: seg.z1 });
    candidates.push({ x: seg.x2, z: seg.z2 });
  });
  return candidates;
}

function redrawBuildPreview(rubberBandPoint) {
  clearBuildPreview();
  if (!buildMode) return;

  const points = rubberBandPoint ? [...buildPoints, rubberBandPoint] : buildPoints;

  // Alignment guides — a horizontal guide when the cursor is nearly level
  // (same Z) with SOME reference point, a vertical one when nearly in line
  // (same X) with one. Picks the single CLOSEST aligned candidate per axis
  // (not one line per candidate) so lining up with a room full of corners
  // doesn't paper the screen with overlapping guides.
  if (rubberBandPoint) {
    const candidates = collectAlignmentCandidates();
    let bestHorizontal = null, bestHorizontalDist = BUILD_GUIDE_ALIGN_TOLERANCE_M;
    let bestVertical = null, bestVerticalDist = BUILD_GUIDE_ALIGN_TOLERANCE_M;

    candidates.forEach((candidate) => {
      const dz = Math.abs(rubberBandPoint.z - candidate.z);
      if (dz <= bestHorizontalDist) {
        bestHorizontalDist = dz;
        bestHorizontal = candidate;
      }
      const dx = Math.abs(rubberBandPoint.x - candidate.x);
      if (dx <= bestVerticalDist) {
        bestVerticalDist = dx;
        bestVertical = candidate;
      }
    });

    if (bestHorizontal) addGuideLine(bestHorizontal.x, bestHorizontal.z, 'x');
    if (bestVertical) addGuideLine(bestVertical.x, bestVertical.z, 'z');
  }

  points.forEach((point, index) => {
    const isRubberBand = rubberBandPoint && index === points.length - 1;
    const marker = new THREE.Mesh(
      new THREE.SphereGeometry(0.05, 12, 12),
      new THREE.MeshBasicMaterial({ color: BUILD_MARKER_COLOR, opacity: isRubberBand ? 0.5 : 1, transparent: isRubberBand }),
    );
    marker.position.set(point.x, 0.05, point.z);
    buildPreviewGroup.add(marker);

    // "Snapped to an existing corner" indicator — a bright ring around the
    // point, the only visual difference between "the wall will start/end
    // exactly on that corner" and "it'll land wherever the cursor happens to
    // be." Without this, snapping was silent — the marker looked identical
    // either way, so there was no confirmation snapping actually happened.
    if (point.snapped) {
      const ring = new THREE.Mesh(
        new THREE.RingGeometry(0.09, 0.12, 24),
        new THREE.MeshBasicMaterial({ color: 0xffffff, side: THREE.DoubleSide, transparent: true, opacity: 0.9 }),
      );
      ring.rotation.x = -Math.PI / 2;
      ring.position.set(point.x, 0.052, point.z);
      buildPreviewGroup.add(ring);
    }
  });

  if (points.length >= 2) {
    const positions = points.flatMap((point) => [point.x, 0.05, point.z]);
    const lineGeometry = new THREE.BufferGeometry();
    lineGeometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
    const line = new THREE.Line(
      lineGeometry,
      new THREE.LineBasicMaterial({ color: BUILD_MARKER_COLOR }),
    );
    buildPreviewGroup.add(line);
  }
}

function handleBuildClick(event) {
  updatePointerNdc(event);
  raycaster.setFromCamera(pointerNdc, camera);

  const hitPoint = new THREE.Vector3();
  if (!raycaster.ray.intersectPlane(floorPlane, hitPoint)) return;

  const locked = computeLockedBuildPoint(hitPoint.x, hitPoint.z, event);
  const snapped = snapBuildPoint(locked.x, locked.z);

  // Clicking back on the room's own starting corner closes the polygon —
  // treat that as "finish" (the same action the explicit "Zakończ obrys"
  // button performs) instead of silently appending a near-duplicate point
  // and leaving the shape looking closed while still waiting for more
  // clicks.
  if (buildMode === 'room' && buildPoints.length >= 3) {
    const first = buildPoints[0];
    const dx = snapped.x - first.x, dz = snapped.z - first.z;
    if (dx * dx + dz * dz <= BUILD_SNAP_DISTANCE_M * BUILD_SNAP_DISTANCE_M) {
      finishRoomDraw();
      return;
    }
  }

  buildPoints.push(snapped);
  post('buildProgress', { mode: buildMode, count: buildPoints.length });

  if (buildMode === 'wall' && buildPoints.length === 2) {
    post('wallDrawn', {
      start: { x: buildPoints[0].x, y: buildPoints[0].z },
      end: { x: buildPoints[1].x, y: buildPoints[1].z },
      is_virtual: buildIsVirtual,
      thickness_m: buildThicknessM,
    });
    // Continue the chain from the just-placed endpoint (not an empty
    // buildPoints) — a multi-wall shape (e.g. a square) only needs one
    // click per additional corner this way, matching floor_plan's own
    // wall tool (walls finish implicitly on each click, continuing from
    // wherever the last one ended) instead of forcing a fresh two-click
    // wall for every single segment. Escape/V/S (cancelBuild) is still
    // the only way to actually stop the chain.
    buildPoints = [buildPoints[1]];
    post('buildProgress', { mode: buildMode, count: buildPoints.length });
  }

  if (buildMode === 'stair' && buildPoints.length === 2) {
    post('stairDrawn', {
      start: { x: buildPoints[0].x, y: buildPoints[0].z },
      end: { x: buildPoints[1].x, y: buildPoints[1].z },
      width_m: DEFAULT_STAIR_WIDTH_M,
    });
    // Unlike walls, a stair run doesn't chain into the next one — each pair
    // of clicks is its own independent flight (a floor realistically has
    // one, maybe two disconnected staircases, never a connected loop of
    // them the way walls form room outlines).
    buildPoints = [];
    post('buildProgress', { mode: buildMode, count: 0 });
  }

  redrawBuildPreview();
}

function finishRoomDraw() {
  if (buildMode !== 'room' || buildPoints.length < 3) return;

  post('roomDrawn', {
    points: buildPoints.map((point) => ({ x: point.x, y: point.z })),
  });
  buildPoints = []; // stay in room mode — chain another virtual room right away
  post('buildProgress', { mode: buildMode, count: 0 });
  redrawBuildPreview();
}

// Selecting an item/wall/floor is committed on pointerUP, not pointerDOWN —
// only if the pointer barely moved in between (a real click, not a drag
// used to orbit/pan the camera). Without this, starting an orbit-drag with
// ANY mouse button on top of the floor (or a wall/item) also selected it,
// since LEFT-button-down is used both to begin OrbitControls' rotate drag
// and, previously, to select immediately. Pivot retargeting ("grab and
// rotate" — see below) is NOT deferred, since that's meant to fire the
// instant a drag begins, not only on a clean click.
const CLICK_MOVE_THRESHOLD_PX = 6;
let pointerDownX = 0;
let pointerDownY = 0;

function onPointerDown(event) {
  // Checked before every mode branch below — the minimap is a navigation
  // shortcut, not part of any of them, and always wins if the click lands
  // on it regardless of what tool/mode is currently active.
  if (event.button === 0 && isPointerOverMinimap(event)) {
    handleMinimapClick(event);
    return;
  }
  // Same reasoning as the minimap above — a navigation shortcut, always
  // wins regardless of the active tool/mode.
  if (event.button === 0 && isPointerOverAxisGizmo(event)) {
    handleAxisGizmoClick(event);
    return;
  }

  if (walkModeEnabled) {
    if (event.button === 0) walkLooking = true;
    return;
  }

  if (measureModeEnabled) {
    handleMeasureClick(event);
    return;
  }

  if (buildMode) {
    handleBuildClick(event);
    return;
  }

  // Clicking anywhere on a dimmed adjacent floor switches to it (§6) — the
  // SketchUp/Revit-style "click the floor you want to work on" navigation
  // the true-stacking model exists for, checked before the normal item/
  // wall/floor pick below since adjacent-floor geometry isn't part of that
  // pick at all (it's deliberately non-interactive otherwise).
  if (event.button === 0 && (adjacentFloorGroups.below || adjacentFloorGroups.above)) {
    updatePointerNdc(event);
    raycaster.setFromCamera(pointerNdc, camera);

    const shiftCameraByAdjacentOffset = (adjacentGroup) => {
      const newPos = camera.position.clone();
      newPos.y += adjacentGroup.position.y;
      const newTarget = controls.target.clone();
      newTarget.y += adjacentGroup.position.y;
      animateCameraTo(newPos, newTarget);
    };

    if (adjacentFloorGroups.below && raycaster.intersectObject(adjacentFloorGroups.below, true).length) {
      shiftCameraByAdjacentOffset(adjacentFloorGroups.below);
      post('switchFloorRequested', { direction: 'below' });
      return;
    }
    if (adjacentFloorGroups.above && raycaster.intersectObject(adjacentFloorGroups.above, true).length) {
      shiftCameraByAdjacentOffset(adjacentFloorGroups.above);
      post('switchFloorRequested', { direction: 'above' });
      return;
    }
  }

  // Wall endpoint handles (only present when a wall is selected) take
  // priority over the normal item/wall/floor pick below — grabbing one
  // starts a preview-only drag, see wallEndpointDragState's doc comment.
  if (event.button === 0 && wallEndpointHandlesGroup.children.length) {
    updatePointerNdc(event);
    raycaster.setFromCamera(pointerNdc, camera);
    const handleHits = raycaster.intersectObjects(wallEndpointHandlesGroup.children);
    if (handleHits.length) {
      const { wallId, endpoint } = handleHits[0].object.userData;
      controls.enabled = false;
      wallEndpointDragState = { wallId, endpoint, previewLine: null };
      return;
    }
  }

  // Placing a new door/window opening (FINAL_VISION.md §4) — a single click
  // on the currently selected wall commits it there and then, no multi-step
  // draw like Buduj's walls/rooms. Only tests the selected wall's own
  // hitbox (not every wall), so a stray click elsewhere while placing mode
  // is on just falls through to the normal pick below instead of silently
  // placing on whatever wall happens to be under the cursor.
  if (event.button === 0 && placingOpeningKind && selectedWallId) {
    const wallHitbox = wallHitboxMeshesByWallId.get(selectedWallId);
    const seg = wallSegmentsById.get(selectedWallId);
    if (wallHitbox && seg) {
      updatePointerNdc(event);
      raycaster.setFromCamera(pointerNdc, camera);
      const hits = raycaster.intersectObject(wallHitbox);
      if (hits.length) {
        const hit = hits[0].point;
        const dx = seg.x2 - seg.x1, dz = seg.z2 - seg.z1;
        const lengthSq = dx * dx + dz * dz;
        const t = lengthSq > 0
          ? THREE.MathUtils.clamp(((hit.x - seg.x1) * dx + (hit.z - seg.z1) * dz) / lengthSq, 0, 1)
          : 0.5;

        post('openingPlaced', { wall_id: selectedWallId, kind: placingOpeningKind, position: t });
        placingOpeningKind = null;
        return;
      }
    }
  }

  pointerDownX = event.clientX;
  pointerDownY = event.clientY;

  const hitId = pickItemAt(event);

  if (hitId && hitId === selectedItemId) {
    controls.enabled = false;
    dragState = { itemId: hitId };
    return;
  }

  if (hitId) return; // selection commits on pointerUp

  const wallHitboxHits = raycaster.intersectObjects([...wallHitboxMeshesByWallId.values()]);
  if (wallHitboxHits.length) {
    // Deliberately NOT retargeting the orbit pivot on a wall hit (unlike
    // the floor case below) — this is heading toward a select action, and
    // re-centering the pivot on every wall click reads as the camera
    // silently nudging instead of the click registering as a selection.
    return;
  }

  const floorHits = raycaster.intersectObjects([...floorMeshesByRoomId.values()]);
  if (floorHits.length) {
    // Floor clicks keep the existing "grab and rotate" pivot retargeting —
    // orbiting around wherever you're looking on the floor is the common
    // case and wasn't the behavior anyone reported as confusing. This
    // fires immediately (not deferred) since it's about the drag that may
    // follow, not the click-selection itself.
    if (event.button === 0) controls.target.copy(floorHits[0].point);
    return;
  }

  // Retarget the orbit pivot to wherever the cursor is pointing (any other
  // part of the room group — furniture edges, zone overlays, etc.) rather
  // than leaving it at a fixed point. Only for the button that actually
  // rotates (LEFT — see controls.mouseButtons above); a pan drag shouldn't
  // also silently re-center the rotation pivot.
  if (event.button === 0) {
    const roomHits = raycaster.intersectObjects(roomGroup.children, true);
    if (roomHits.length) controls.target.copy(roomHits[0].point);
  }
}

// Runs on pointerUp when the movement since pointerDown was below
// CLICK_MOVE_THRESHOLD_PX — i.e. this was a click, not the end of an
// orbit/pan drag. Re-raycasts from the release position rather than
// reusing whatever pointerDown found, since click and release can differ
// by a few px even under the threshold.
function commitClickSelection(event) {
  updatePointerNdc(event);
  raycaster.setFromCamera(pointerNdc, camera);

  const itemHits = raycaster.intersectObjects([...itemMeshesById.values()]);
  if (itemHits.length) {
    const itemId = itemHits[0].object.userData.itemId;
    setSelection(itemId);
    selectWall(null);
    selectFloor(null);
    post('objectSelected', { id: itemId });
    return;
  }

  const wallHitboxHits = raycaster.intersectObjects([...wallHitboxMeshesByWallId.values()]);
  if (wallHitboxHits.length) {
    const wallId = wallHitboxHits[0].object.userData.wallId;
    setSelection(null);
    selectFloor(null);
    selectWall(wallId);
    post('zoneSelected', { id: wallId });
    return;
  }

  const floorHits = raycaster.intersectObjects([...floorMeshesByRoomId.values()]);
  if (floorHits.length) {
    const roomId = floorHits[0].object.userData.roomId;
    setSelection(null);
    selectWall(null);
    selectFloor(roomId);
    post('roomSelected', { id: roomId });
    return;
  }

  if (selectedItemId || selectedWallId || selectedRoomId) {
    setSelection(null);
    selectWall(null);
    selectFloor(null);
    post('objectSelected', { id: null });
  }
}

function onPointerMove(event) {
  if (walkModeEnabled) {
    if (!walkLooking) return;
    walkYaw -= event.movementX * WALK_LOOK_SENSITIVITY;
    walkPitch -= event.movementY * WALK_LOOK_SENSITIVITY;
    walkPitch = THREE.MathUtils.clamp(walkPitch, -Math.PI / 2 + 0.05, Math.PI / 2 - 0.05);
    applyWalkLookRotation();
    return;
  }

  if (measureModeEnabled) {
    updateMeasureRubberBand(event);
    return;
  }

  if (buildMode) {
    // No `buildPoints.length > 0` gate — the hover/snap preview (including
    // the "snapped to an existing corner" ring) needs to show for the VERY
    // FIRST point of a fresh draw too, not just once a point is already
    // placed. Without this, there was no visual confirmation before that
    // first click, making it easy to start a new wall/room slightly off an
    // existing corner instead of flush against it.
    updatePointerNdc(event);
    raycaster.setFromCamera(pointerNdc, camera);
    const hitPoint = new THREE.Vector3();
    if (raycaster.ray.intersectPlane(floorPlane, hitPoint)) {
      const locked = computeLockedBuildPoint(hitPoint.x, hitPoint.z, event);
      redrawBuildPreview(snapBuildPoint(locked.x, locked.z));
    }
    return;
  }

  if (wallEndpointDragState) {
    updatePointerNdc(event);
    raycaster.setFromCamera(pointerNdc, camera);
    const hitPoint = new THREE.Vector3();
    if (!raycaster.ray.intersectPlane(floorPlane, hitPoint)) return;
    updateWallEndpointDragPreview(snapBuildPoint(hitPoint.x, hitPoint.z));
    return;
  }

  if (!dragState) return;

  updatePointerNdc(event);
  raycaster.setFromCamera(pointerNdc, camera);

  const hitPoint = new THREE.Vector3();
  if (!raycaster.ray.intersectPlane(floorPlane, hitPoint)) return;

  const mesh = itemMeshesById.get(dragState.itemId);
  if (!mesh) return;

  mesh.position.x = hitPoint.x;
  mesh.position.z = hitPoint.z;
  applyWallSnap(mesh);
}

// Moves just the handle sphere + a rubber-band preview line to the fixed
// (non-dragged) endpoint — never touches the real wall geometry, see
// wallEndpointDragState's doc comment for why. `point.pendingPoint` is
// cached so onPointerUp commits exactly what was last shown, rather than
// re-raycasting from the mouseup event (which could theoretically land at
// a slightly different pixel than the last mousemove).
function updateWallEndpointDragPreview(point) {
  const { wallId, endpoint } = wallEndpointDragState;
  const seg = wallSegmentsById.get(wallId);
  if (!seg) return;

  const handle = wallEndpointHandlesGroup.children.find(
    (child) => child.userData.kind === 'wallEndpointHandle'
      && child.userData.wallId === wallId
      && child.userData.endpoint === endpoint,
  );
  if (handle) handle.position.set(point.x, 0.11, point.z);

  const fixed = endpoint === 'start' ? { x: seg.x2, z: seg.z2 } : { x: seg.x1, z: seg.z1 };

  if (wallEndpointDragState.previewLine) {
    wallEndpointHandlesGroup.remove(wallEndpointDragState.previewLine);
    disposeObject(wallEndpointDragState.previewLine);
  }

  const geometry = new THREE.BufferGeometry().setFromPoints([
    new THREE.Vector3(fixed.x, 0.11, fixed.z),
    new THREE.Vector3(point.x, 0.11, point.z),
  ]);
  const line = new THREE.Line(geometry, new THREE.LineBasicMaterial({ color: WALL_ENDPOINT_HANDLE_COLOR }));
  wallEndpointHandlesGroup.add(line);
  wallEndpointDragState.previewLine = line;
  wallEndpointDragState.pendingPoint = point;
}

function onPointerUp(event) {
  if (walkModeEnabled) {
    if (event.button === 0) walkLooking = false;
    return;
  }

  if (measureModeEnabled) return;

  if (wallEndpointDragState) {
    controls.enabled = true;
    const { wallId, endpoint, pendingPoint } = wallEndpointDragState;
    // pendingPoint is only unset if pointerup fires with literally no prior
    // pointermove (a plain click-without-drag on the handle) — nothing to
    // commit in that case, just drop back out of the drag state.
    if (pendingPoint) {
      post('wallEndpointMoved', {
        wall_id: wallId,
        endpoint,
        point: { x: pendingPoint.x, y: pendingPoint.z },
      });
    }
    wallEndpointDragState = null;
    return;
  }

  if (!dragState) {
    controls.enabled = true;

    if (!buildMode) {
      const dx = event.clientX - pointerDownX;
      const dy = event.clientY - pointerDownY;
      if (Math.hypot(dx, dy) < CLICK_MOVE_THRESHOLD_PX) commitClickSelection(event);
    }
    return;
  }

  const mesh = itemMeshesById.get(dragState.itemId);
  if (mesh) {
    post('dragEnded', {
      id: dragState.itemId,
      position: { x: mesh.position.x, y: mesh.position.z, z: mesh.position.y - DEFAULT_ITEM_SIZE.heightM / 2 },
      rotation_deg: -mesh.rotation.y * (180 / Math.PI),
    });
  }

  dragState = null;
  controls.enabled = true;
}

// ---------------------------------------------------------------------------
// Bridge dispatch
// ---------------------------------------------------------------------------

window.onFlutterMessage = function (message) {
  if (!ready) return;

  try {
    switch (message.type) {
      case 'loadScene':
        loadScene(message.payload);
        break;
      case 'placeItem':
        placeItem(message.payload);
        break;
      case 'moveItem':
        moveItem(message.payload);
        break;
      case 'removeItem':
        removeItem(message.payload);
        break;
      case 'setWallZoneMaterial':
        setWallZoneMaterial(message.payload);
        break;
      case 'setWholeWallMaterial':
        setWholeWallMaterial(message.payload);
        break;
      case 'setFloorMaterial':
        setFloorMaterial(message.payload);
        break;
      case 'previewMaterial':
        previewMaterial(message.payload);
        break;
      case 'setCameraPreset':
        setCameraPreset(message.payload.preset);
        break;
      case 'setSelection':
        setSelection(message.payload.id);
        break;
      case 'addWall':
        addWall(message.payload);
        break;
      case 'addRoom':
        addRoom(message.payload);
        break;
      case 'setBuildMode':
        setBuildMode(message.payload.mode, message.payload.is_virtual, message.payload.thickness_m);
        break;
      case 'cancelBuild':
        cancelBuild();
        break;
      case 'finishRoomDraw':
        finishRoomDraw();
        break;
      case 'setCutawayEnabled':
        setCutawayEnabled(message.payload.enabled);
        break;
      case 'updateWallThickness':
        updateWallThickness(message.payload);
        break;
      case 'removeWall':
        removeWall(message.payload);
        break;
      case 'removeRoom':
        removeRoom(message.payload);
        break;
      case 'setWalkMode':
        setWalkModeEnabled(message.payload.enabled);
        break;
      case 'setMeasureMode':
        setMeasureModeEnabled(message.payload.enabled);
        break;
      case 'captureScreenshot':
        captureScreenshot();
        break;
      case 'captureGltfExport':
        captureGltfExport();
        break;
      case 'captureTopDownPlan':
        captureTopDownPlan();
        break;
      case 'setDimensionsEnabled':
        setDimensionsEnabled(message.payload.enabled);
        break;
      case 'setPresentationModeEnabled':
        setPresentationModeEnabled(message.payload.enabled);
        break;
      case 'setAngleLock':
        setAngleLock(message.payload);
        break;
      case 'setPlacingOpening':
        setPlacingOpening(message.payload.kind);
        break;
      default:
        post('error', { message: `Unknown message type: ${message.type}` });
    }
  } catch (err) {
    post('error', { message: String(err && err.message || err) });
  }
};

initThree();
