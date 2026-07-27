/// Editor screen for the 3D room ("tryb Simsów"). Faza 1 status: real
/// three.js viewer + toolbar (3 tryby: Meble/Ściany-Płytki/Podłoga) + camera
/// presets + undo/redo + drag-to-move + furniture catalog + inspector +
/// wall/floor material pickers + save/load persistence, all wired end to
/// end through `room_scene_actions.dart`. Still missing: door/window
/// cutouts, real glTF models, and real floor_plan integration (the "Scena
/// testowa" button is a dev-only stand-in for a floor_plan-sourced scene —
/// see docs/sims_mode/IMPLEMENTATION_CHECKLIST.md).
///
/// `roomSceneActionsProvider` is overridden (via a page-scoped
/// `ProviderScope`) to wire `RoomSceneActions.onCommand` straight to the
/// live `Room3dWebViewState` — this is the one place in the module that
/// connects the "single source of truth" state layer to the "dumb
/// renderer" viewer, per docs/sims_mode/ARCHITECTURE.md section 6.
library;

import 'dart:convert';

import 'package:core/shell/manager/bar_manager.dart';
import 'package:core/theme/apptheme.dart';
import 'package:core/ui/device_type_util.dart';
import 'package:core/ui/side_menu/slide_rotate_menu.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../actions/room_scene_actions.dart';
import '../model/room_scene.dart';
import '../model/room_scene_builder.dart';
import '../providers/room_3d_api_service.dart';
import '../providers/room_scene_provider.dart';
import '../viewer/room_3d_webview.dart';
import 'panels/build_panel.dart';
import 'panels/floor_material_panel.dart';
import 'panels/furniture_catalog_panel.dart';
import 'panels/furniture_item_inspector.dart';
import 'panels/wall_material_panel.dart';
import 'room_3d_toolbar.dart';

/// Public entry point — wraps the actual editor in the app's standard
/// chrome (`BarManager`, matching `FloorPlanBuilderCrmPage`'s convention)
/// so the page gets a sidebar/navigation instead of floating chromeless.
class Room3dEditorPage extends ConsumerWidget {
  /// If set, this is an existing `RoomSceneProject` id — the page loads its
  /// saved scene on open and saves back to the same project. If null,
  /// the first "Zapisz" click creates a new project.
  final String? projectId;

  /// If set (and [projectId] isn't), this is a `floor_plans.FloorPlanProject`
  /// id — the entry point for floor_plan's "Tryb 3D" button. The page
  /// converts that plan's latest document into a `RoomScene` via
  /// `RoomSceneBuilder.loadFromFloorPlanProject` and loads it. A later
  /// "Zapisz" still creates a *new*, separate `RoomSceneProject` (rooms and
  /// floor plans are deliberately independent persisted records — see
  /// docs/sims_mode/ARCHITECTURE.md section 1) tagged with this id as its
  /// `target_object_id` so the two stay traceable to each other.
  final String? floorPlanProjectId;

  Room3dEditorPage({super.key, this.projectId, this.floorPlanProjectId});

  final GlobalKey<SideMenuState> sideMenuKey = GlobalKey<SideMenuState>();

  // Created here, not inside _Room3dEditorContentState, so the
  // roomSceneActionsProvider override below can reference it — see that
  // override's doc comment for why this whole key had to move up a level.
  final GlobalKey<Room3dWebViewState> webViewKey = GlobalKey<Room3dWebViewState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wraps `_Room3dEditorContent` itself (not just its build() output, as
    // an earlier version did) — `ProviderScope.overrides` only reach
    // widgets BELOW the scope in the tree. Overriding from inside
    // `_Room3dEditorContent.build()` meant the override never reached that
    // widget's own State object (`_Room3dEditorContentState` sits above the
    // scope it itself creates), so `_onBridgeMessage`'s
    // `ref.read(roomSceneActionsProvider)` calls (addWall/addRoom/moveItem)
    // were silently resolving the un-overridden root provider — one with
    // `onCommand: null`. Riverpod state mutated correctly, but the matching
    // JS bridge command never fired, so e.g. a newly-drawn wall updated the
    // scene but never rendered — the actual cause of "can't place a wall."
    final content = ProviderScope(
      overrides: [
        roomSceneActionsProvider.overrideWith(
          (ref) => RoomSceneActions(
            ref,
            onCommand: (type, payload) => webViewKey.currentState?.sendCommand(type, payload),
          ),
        ),
      ],
      child: _Room3dEditorContent(
        webViewKey: webViewKey,
        projectId: projectId,
        floorPlanProjectId: floorPlanProjectId,
      ),
    );

    return BarManager(
      sideMenuKey: sideMenuKey,
      appModule: AppModule.portal,
      isChildExpanded: true,
      enableScrool: true,
      isTopAppBarOff: true,
      isTopAppBarOffMobile: false,
      isBottomBarOff: true,
      isTopAppBarHoveroverUI: true,
      layoutTypePc: LayoutTypePc.stack,
      layoutTypeTablet: LayoutTypeTablet.stack,
      layoutTypeMobile: LayoutTypeMobile.stack,
      paddingPc: 0,
      paddingTablet: 0,
      paddingMobile: 0,
      childPc: content,
      childTablet: content,
      childMobile: Builder(
        builder: (context) {
          final topPadding = TopAppBarSize.resolve(context);
          return Column(
            children: [
              SizedBox(height: topPadding),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class _Room3dEditorContent extends ConsumerStatefulWidget {
  final GlobalKey<Room3dWebViewState> webViewKey;
  final String? projectId;
  final String? floorPlanProjectId;

  const _Room3dEditorContent({required this.webViewKey, this.projectId, this.floorPlanProjectId});

  @override
  ConsumerState<_Room3dEditorContent> createState() => _Room3dEditorContentState();
}

class _Room3dEditorContentState extends ConsumerState<_Room3dEditorContent> {
  GlobalKey<Room3dWebViewState> get _webViewKey => widget.webViewKey;
  Room3dTool _selectedTool = Room3dTool.furniture;
  String? _selectedItemId;
  String? _selectedWallId;
  String? _selectedRoomId;

  /// 'door' | 'window' | null — see WallMaterialPanel's "Dodaj drzwi"/
  /// "Dodaj okno" buttons and scene.js's setPlacingOpening handling.
  String? _placingOpeningKind;

  String? _buildMode; // 'wall' | 'room' | null — see BuildPanel
  bool _buildIsVirtualWall = false;
  double _buildThicknessM = 0.15;
  int _buildPointCount = 0;
  bool _angleLockEnabled = true;
  double _angleStepDegrees = 90;
  bool _cutawayEnabled = true;
  bool _walkModeEnabled = false;
  bool _measureModeEnabled = false;
  bool _dimensionsEnabled = false;
  bool _presentationModeEnabled = false;

  String? _currentProjectId;
  String? _floorPlanSourceId;
  bool _isSaving = false;
  String _saveStatusLabel = '';

  // Set when a floor needs loading into the viewer before it's finished its
  // own JS-side init — `Room3dWebViewState._send` silently drops commands
  // sent before `ready`, so a `loadScene` fired right on page-open (the
  // saved-project auto-load path) would otherwise just be lost. Just a flag,
  // not the scene/floor itself — by the time `ready` fires, `loadScene` has
  // already updated `roomSceneProvider`'s state, so re-reading it fresh at
  // flush time is simpler than snapshotting a value that could go stale.
  bool _hasPendingSceneToLoad = false;

  @override
  void initState() {
    super.initState();
    _currentProjectId = widget.projectId;

    if (_currentProjectId != null) {
      _loadExistingProject(_currentProjectId!);
    } else if (widget.floorPlanProjectId != null) {
      _floorPlanSourceId = widget.floorPlanProjectId;
      _loadFromFloorPlan(widget.floorPlanProjectId!);
    }
  }

  void _onBridgeMessage(String type, Map<String, dynamic> payload) {
    switch (type) {
      case 'ready':
        if (_hasPendingSceneToLoad) {
          _hasPendingSceneToLoad = false;
          final state = ref.read(roomSceneProvider);
          if (state.scene != null) {
            _webViewKey.currentState?.sendCommand(
              'loadScene',
              ref.read(roomSceneActionsProvider).floorStackPayload(state.scene!, state.activeFloorIndex),
            );
          }
        }
        break;

      case 'objectSelected':
        final itemId = payload['id']?.toString();
        setState(() {
          _selectedItemId = itemId;
          // The viewer clears all three selection kinds together on an
          // empty-space click (see scene.js onPointerDown) — mirror that
          // here so a stale wall/room highlight doesn't linger in Flutter
          // state after the 3D highlight itself has already cleared.
          if (itemId == null) {
            _selectedWallId = null;
            _selectedRoomId = null;
          }
        });
        break;

      case 'zoneSelected':
        setState(() {
          _selectedWallId = payload['id']?.toString();
          _selectedRoomId = null;
          _placingOpeningKind = null;
        });
        break;

      case 'roomSelected':
        setState(() {
          _selectedRoomId = payload['id']?.toString();
          _selectedWallId = null;
          _placingOpeningKind = null;
        });
        break;

      case 'dragEnded':
        final positionRaw = Map<String, dynamic>.from(payload['position'] ?? {});
        ref.read(roomSceneActionsProvider).moveItem(
              itemId: payload['id'].toString(),
              position: RoomPoint3.fromJson(positionRaw),
              rotationDeg: (payload['rotation_deg'] as num?)?.toDouble(),
            );
        break;

      case 'wallEndpointMoved':
        final pointRaw = Map<String, dynamic>.from(payload['point'] ?? {});
        ref.read(roomSceneActionsProvider).updateWallEndpoint(
              wallId: payload['wall_id'].toString(),
              endpoint: payload['endpoint'].toString(),
              point: RoomPoint2.fromJson(pointRaw),
            );
        break;

      case 'openingPlaced':
        ref.read(roomSceneActionsProvider).addOpening(
              wallId: payload['wall_id'].toString(),
              kind: RoomOpeningKind.fromKey(payload['kind']?.toString()),
              position: (payload['position'] as num?)?.toDouble() ?? 0.5,
            );
        setState(() => _placingOpeningKind = null);
        break;

      case 'switchFloorRequested':
        // Clicking a dimmed adjacent floor (§6's true stacking) — reuses
        // `_onFloorSelected` (not a bare `setActiveFloor` call) so the
        // stale-selection cleanup every OTHER way of switching floors
        // already gets applies here too.
        final direction = payload['direction']?.toString();
        final currentIndex = ref.read(roomSceneProvider).activeFloorIndex;
        final delta = direction == 'below' ? -1 : (direction == 'above' ? 1 : 0);
        if (delta != 0) _onFloorSelected(currentIndex + delta);
        break;

      case 'buildProgress':
        setState(() => _buildPointCount = (payload['count'] as num?)?.toInt() ?? 0);
        break;

      case 'buildModeChanged':
        // The viewer's own W/R/Escape/V/S hotkeys (scene.js's onKeyDown —
        // keyboard events inside the embedded WebView never reach a
        // Flutter-side Focus/onKeyEvent listener, so those shortcuts are
        // handled JS-side, not here) can change build mode without Flutter
        // ever calling setBuildMode/cancelBuild itself. Mirror that into
        // Flutter state so the toolbar/panel highlight stays in sync,
        // switching the toolbar into Buduj too if a hotkey started a draw
        // from a different tool — same as floor_plan's W/R jumping straight
        // to that tool from anywhere.
        final newMode = payload['mode']?.toString();
        setState(() {
          _buildMode = newMode;
          _buildPointCount = 0;
          if (newMode != null && _selectedTool != Room3dTool.build) {
            _selectedTool = Room3dTool.build;
          }
        });
        break;

      case 'wallDrawn':
        final start = RoomPoint2.fromJson(Map<String, dynamic>.from(payload['start'] ?? {}));
        final end = RoomPoint2.fromJson(Map<String, dynamic>.from(payload['end'] ?? {}));
        ref.read(roomSceneActionsProvider).addWall(
              id: 'wall_${DateTime.now().microsecondsSinceEpoch}',
              start: start,
              end: end,
              isVirtual: payload['is_virtual'] == true,
              thicknessM: (payload['thickness_m'] as num?)?.toDouble() ?? 0.15,
            );
        break;

      case 'stairDrawn':
        final start = RoomPoint2.fromJson(Map<String, dynamic>.from(payload['start'] ?? {}));
        final end = RoomPoint2.fromJson(Map<String, dynamic>.from(payload['end'] ?? {}));
        ref.read(roomSceneActionsProvider).addStair(
              id: 'stair_${DateTime.now().microsecondsSinceEpoch}',
              start: start,
              end: end,
              widthM: (payload['width_m'] as num?)?.toDouble() ?? 1.0,
            );
        break;

      case 'cutawayToggled':
        // Same reasoning as buildModeChanged — the C hotkey lives in
        // scene.js (keyboard events inside the WebView never reach a
        // Flutter-side listener), so a hotkey-driven toggle needs to be
        // mirrored back into Flutter state to keep the toolbar button's
        // pressed/unpressed look in sync.
        setState(() => _cutawayEnabled = payload['enabled'] == true);
        break;

      case 'walkModeChanged':
        // Same reasoning as cutawayToggled — F is a scene.js-side hotkey.
        setState(() => _walkModeEnabled = payload['enabled'] == true);
        break;

      case 'measureModeChanged':
        // Same reasoning as cutawayToggled/walkModeChanged — M is a
        // scene.js-side hotkey.
        setState(() => _measureModeEnabled = payload['enabled'] == true);
        break;

      case 'roomDrawn':
        final points = ((payload['points'] as List?) ?? [])
            .map((raw) => RoomPoint2.fromJson(Map<String, dynamic>.from(raw)))
            .toList();
        ref.read(roomSceneActionsProvider).addRoom(
              id: 'room_${DateTime.now().microsecondsSinceEpoch}',
              name: 'Wirtualny pokój',
              points: points,
            );
        break;

      case 'screenshotCaptured':
        _saveScreenshot(payload['data_url']?.toString());
        break;

      case 'gltfExportReady':
        _saveGltfExport(payload['base64']?.toString());
        break;

      case 'topDownPlanCaptured':
        _saveTopDownPlan(payload['data_url']?.toString());
        break;

      case 'undoRequested':
        // Global Ctrl+Z inside the viewport (FINAL_VISION.md §2.2) — same
        // call the existing toolbar undo button already makes.
        ref.read(roomSceneActionsProvider).undo();
        break;

      case 'redoRequested':
        ref.read(roomSceneActionsProvider).redo();
        break;

      case 'deleteSelectedItemRequested':
        // Delete/Backspace inside the viewport (§2.2) — mirrors
        // FurnitureItemInspector's own delete button exactly (removeItem
        // then clear the selection so the inspector panel closes).
        final itemId = payload['id']?.toString();
        if (itemId != null) {
          ref.read(roomSceneActionsProvider).removeItem(itemId);
          setState(() => _selectedItemId = null);
        }
        break;

      case 'error':
        final message = payload['message']?.toString() ?? 'unknown viewer error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('room_3d viewer: $message')),
        );
        break;
    }
  }

  /// Decodes the PNG data URL `scene.js`'s `captureScreenshot()` sends back
  /// and hands it to `FileSaver`'s native "Save As" dialog — same flow as
  /// `floor_plan_export_service.dart`'s `saveFile`, no export-format choice
  /// needed here since this is always a single PNG frame, not a document.
  Future<void> _saveScreenshot(String? dataUrl) async {
    if (dataUrl == null || !dataUrl.contains(',')) return;

    try {
      final bytes = base64Decode(dataUrl.split(',').last);
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');

      final savedPath = await FileSaver.instance.saveAs(
        name: 'room3d_$timestamp',
        bytes: bytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );

      if (!mounted) return;
      if (savedPath == null || savedPath.trim().isEmpty) return; // user cancelled the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zrzut ekranu zapisany: $savedPath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać zrzutu ekranu: $e')),
      );
    }
  }

  /// Decodes the binary .glb `scene.js`'s `captureGltfExport()` sends back
  /// (plain base64, no data-URL prefix — unlike the PNG screenshot, there's
  /// no "make it clickable/previewable inline" use case for a 3D model
  /// file, so no reason to pay for the mime-type prefix) and saves it the
  /// same way — `FileSaver`'s native "Save As" dialog.
  Future<void> _saveGltfExport(String? base64) async {
    if (base64 == null || base64.isEmpty) return;

    try {
      final bytes = base64Decode(base64);
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');

      final savedPath = await FileSaver.instance.saveAs(
        name: 'room3d_export_$timestamp',
        bytes: bytes,
        fileExtension: 'glb',
        mimeType: MimeType.other,
        customMimeType: 'model/gltf-binary',
      );

      if (!mounted) return;
      if (savedPath == null || savedPath.trim().isEmpty) return; // user cancelled the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eksport glTF zapisany: $savedPath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać eksportu glTF: $e')),
      );
    }
  }

  /// Same decode-and-`FileSaver` flow as [_saveScreenshot] — the top-down
  /// plan (FINAL_VISION.md §7.4) is also always a single PNG frame, just
  /// composited with wall-length text baked into the pixels by
  /// `captureTopDownPlan()` rather than a live-view HTML overlay.
  Future<void> _saveTopDownPlan(String? dataUrl) async {
    if (dataUrl == null || !dataUrl.contains(',')) return;

    try {
      final bytes = base64Decode(dataUrl.split(',').last);
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');

      final savedPath = await FileSaver.instance.saveAs(
        name: 'room3d_plan_$timestamp',
        bytes: bytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );

      if (!mounted) return;
      if (savedPath == null || savedPath.trim().isEmpty) return; // user cancelled the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan z góry zapisany: $savedPath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać planu: $e')),
      );
    }
  }

  void _setBuildMode(String? mode) {
    setState(() {
      _buildMode = mode;
      _buildPointCount = 0;
    });
    if (mode == null) {
      _webViewKey.currentState?.cancelBuild();
    } else {
      _webViewKey.currentState?.setBuildMode(
        mode,
        isVirtual: _buildIsVirtualWall,
        thicknessM: _buildThicknessM,
      );
    }
  }

  void _setBuildIsVirtualWall(bool value) {
    setState(() {
      _buildIsVirtualWall = value;
      _buildPointCount = 0; // re-sending setBuildMode below resets JS-side points too
    });
    if (_buildMode != null) {
      _webViewKey.currentState?.setBuildMode(
        _buildMode,
        isVirtual: value,
        thicknessM: _buildThicknessM,
      );
    }
  }

  void _setBuildThicknessM(double value) {
    setState(() {
      _buildThicknessM = value;
      _buildPointCount = 0;
    });
    if (_buildMode != null) {
      _webViewKey.currentState?.setBuildMode(
        _buildMode,
        isVirtual: _buildIsVirtualWall,
        thicknessM: value,
      );
    }
  }

  void _setAngleLockEnabled(bool value) {
    setState(() => _angleLockEnabled = value);
    _webViewKey.currentState?.setAngleLock(enabled: value, stepDegrees: _angleStepDegrees);
  }

  void _setAngleStepDegrees(double value) {
    setState(() => _angleStepDegrees = value);
    _webViewKey.currentState?.setAngleLock(enabled: _angleLockEnabled, stepDegrees: value);
  }

  void _setPlacingOpeningKind(String? kind) {
    setState(() => _placingOpeningKind = kind);
    _webViewKey.currentState?.setPlacingOpening(kind);
  }

  void _setCutawayEnabled(bool value) {
    setState(() => _cutawayEnabled = value);
    _webViewKey.currentState?.setCutawayEnabled(value);
  }

  void _setDimensionsEnabled(bool value) {
    setState(() => _dimensionsEnabled = value);
    _webViewKey.currentState?.setDimensionsEnabled(value);
  }

  void _setPresentationModeEnabled(bool value) {
    setState(() => _presentationModeEnabled = value);
    _webViewKey.currentState?.setPresentationModeEnabled(value);
  }

  void _setWalkModeEnabled(bool value) {
    setState(() => _walkModeEnabled = value);
    _webViewKey.currentState?.setWalkMode(value);
  }

  void _setMeasureModeEnabled(bool value) {
    setState(() => _measureModeEnabled = value);
    _webViewKey.currentState?.setMeasureMode(value);
  }

  // Floor switching swaps the viewer's entire scene for a different floor's
  // — any selection held from the previous floor (an item/wall/room id that
  // may not even exist on the new floor) is stale, so clear it here rather
  // than in the scaffold's direct `ref.read` callbacks (matching
  // `onToolChanged`'s existing pattern of side-effecting through this
  // State, not the stateless scaffold).
  void _onFloorSelected(int index) {
    setState(() {
      _selectedItemId = null;
      _selectedWallId = null;
      _selectedRoomId = null;
    });
    ref.read(roomSceneActionsProvider).setActiveFloor(index);
  }

  void _onAddFloor() {
    setState(() {
      _selectedItemId = null;
      _selectedWallId = null;
      _selectedRoomId = null;
    });
    ref.read(roomSceneActionsProvider).addFloor();
  }

  void _onRemoveActiveFloor() {
    setState(() {
      _selectedItemId = null;
      _selectedWallId = null;
      _selectedRoomId = null;
    });
    ref.read(roomSceneActionsProvider).removeFloor(ref.read(roomSceneProvider).activeFloorIndex);
  }

  Future<void> _loadSceneEverywhere(RoomScene scene) async {
    ref.read(roomSceneProvider.notifier).loadScene(scene);
    if (scene.floors.isEmpty) return;

    final webView = _webViewKey.currentState;
    if (webView != null && webView.isReady) {
      await webView.sendCommand(
        'loadScene',
        ref.read(roomSceneActionsProvider).floorStackPayload(scene, ref.read(roomSceneProvider).activeFloorIndex),
      );
    } else {
      _hasPendingSceneToLoad = true;
    }
  }

  Future<void> _loadExistingProject(String projectId) async {
    try {
      final dto = await ref
          .read(room3dApiServiceProvider)
          .getProject(ref: ref, projectId: projectId);

      await _loadSceneEverywhere(RoomScene.fromJson(dto.sceneDocument));

      if (mounted) setState(() => _saveStatusLabel = 'Wczytano zapisaną scenę');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się wczytać sceny: $e')),
      );
    }
  }

  Future<void> _loadFromFloorPlan(String floorPlanProjectId) async {
    try {
      final scene = await RoomSceneBuilder.loadFromFloorPlanProject(
        ref: ref,
        floorPlanProjectId: floorPlanProjectId,
      );

      await _loadSceneEverywhere(scene);

      if (mounted) setState(() => _saveStatusLabel = 'Wczytano z planu nieruchomości');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się wczytać planu: $e')),
      );
    }
  }

  Future<void> _saveScene() async {
    final scene = ref.read(roomSceneProvider).scene;

    if (scene == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak sceny do zapisania — wczytaj najpierw scenę.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final api = ref.read(room3dApiServiceProvider);
      var projectId = _currentProjectId;

      projectId ??= (await api.createProject(
        ref: ref,
        title: 'Scena 3D',
        targetObjectId: _floorPlanSourceId,
        targetAppLabel: _floorPlanSourceId != null ? 'floor_plans' : null,
        targetModel: _floorPlanSourceId != null ? 'floorplanproject' : null,
      ))
          .id;

      await api.saveScene(ref: ref, projectId: projectId, sceneDocument: scene.toJson());

      if (!mounted) return;
      setState(() {
        _currentProjectId = projectId;
        _saveStatusLabel = 'Zapisano ${_formatTime(DateTime.now())}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd zapisu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _loadTestScene() => _loadSceneEverywhere(_buildTestScene());

  RoomScene _buildTestScene() {
    return RoomScene.singleFloor(
      sourceKind: RoomSceneSourceKind.floorPlan,
      sourceId: 'dev_test_scene',
      walls: [
        RoomWall(id: 'w1', start: RoomPoint2(x: 0, y: 0), end: RoomPoint2(x: 4, y: 0)),
        RoomWall(id: 'w2', start: RoomPoint2(x: 4, y: 0), end: RoomPoint2(x: 4, y: 3)),
        RoomWall(id: 'w3', start: RoomPoint2(x: 4, y: 3), end: RoomPoint2(x: 0, y: 3)),
        RoomWall(id: 'w4', start: RoomPoint2(x: 0, y: 3), end: RoomPoint2(x: 0, y: 0)),
      ],
      rooms: [
        RoomRoom(
          id: 'r1',
          name: 'Kuchnia (test)',
          points: [
            RoomPoint2(x: 0, y: 0),
            RoomPoint2(x: 4, y: 0),
            RoomPoint2(x: 4, y: 3),
            RoomPoint2(x: 0, y: 3),
          ],
        ),
      ],
      items: [
        RoomPlacedItem(
          id: 'i1',
          catalogItemId: 'dev:sofa',
          position: RoomPoint3(x: 1, y: 1, z: 0),
          roomId: 'r1',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // No ProviderScope/override here anymore — this widget is now a
    // descendant of the one Room3dEditorPage.build() creates, so plain
    // ref.read(roomSceneActionsProvider) calls (in _onBridgeMessage above,
    // and inside _Room3dEditorScaffold below) all correctly resolve the
    // same overridden instance. See Room3dEditorPage.build()'s comment.
    return _Room3dEditorScaffold(
      webViewKey: _webViewKey,
      selectedTool: _selectedTool,
      selectedItemId: _selectedItemId,
      selectedWallId: _selectedWallId,
      selectedRoomId: _selectedRoomId,
      placingOpeningKind: _placingOpeningKind,
      buildMode: _buildMode,
      buildIsVirtualWall: _buildIsVirtualWall,
      buildThicknessM: _buildThicknessM,
      buildPointCount: _buildPointCount,
      angleLockEnabled: _angleLockEnabled,
      angleStepDegrees: _angleStepDegrees,
      cutawayEnabled: _cutawayEnabled,
      walkModeEnabled: _walkModeEnabled,
      measureModeEnabled: _measureModeEnabled,
      dimensionsEnabled: _dimensionsEnabled,
      presentationModeEnabled: _presentationModeEnabled,
      isSaving: _isSaving,
      saveStatusLabel: _saveStatusLabel,
      onToolChanged: (tool) {
        setState(() => _selectedTool = tool);
        // Leaving the Buduj tool mid-draw should stop consuming viewport
        // clicks as build points — otherwise switching to e.g. Meble
        // still silently drops wall/room corners.
        if (tool != Room3dTool.build && _buildMode != null) _setBuildMode(null);
      },
      onBridgeMessage: _onBridgeMessage,
      onLoadTestScene: _loadTestScene,
      onSave: _saveScene,
      onItemDeleted: () => setState(() => _selectedItemId = null),
      onBuildModeChanged: _setBuildMode,
      onBuildIsVirtualWallChanged: _setBuildIsVirtualWall,
      onBuildThicknessChanged: _setBuildThicknessM,
      onAngleLockEnabledChanged: _setAngleLockEnabled,
      onAngleStepDegreesChanged: _setAngleStepDegrees,
      onPlacingOpeningKindChanged: _setPlacingOpeningKind,
      onFinishRoom: () => _webViewKey.currentState?.finishRoomDraw(),
      onCancelBuild: () => _setBuildMode(null),
      onCutawayEnabledChanged: _setCutawayEnabled,
      onWalkModeEnabledChanged: _setWalkModeEnabled,
      onMeasureModeEnabledChanged: _setMeasureModeEnabled,
      onDimensionsEnabledChanged: _setDimensionsEnabled,
      onPresentationModeEnabledChanged: _setPresentationModeEnabled,
      onFloorSelected: _onFloorSelected,
      onAddFloor: _onAddFloor,
      onRemoveActiveFloor: _onRemoveActiveFloor,
    );
  }
}

String _formatTime(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class _Room3dEditorScaffold extends ConsumerWidget {
  final GlobalKey<Room3dWebViewState> webViewKey;
  final Room3dTool selectedTool;
  final String? selectedItemId;
  final String? selectedWallId;
  final String? selectedRoomId;
  final String? placingOpeningKind;
  final String? buildMode;
  final bool buildIsVirtualWall;
  final double buildThicknessM;
  final int buildPointCount;
  final bool angleLockEnabled;
  final double angleStepDegrees;
  final bool cutawayEnabled;
  final bool walkModeEnabled;
  final bool measureModeEnabled;
  final bool dimensionsEnabled;
  final bool presentationModeEnabled;
  final bool isSaving;
  final String saveStatusLabel;
  final ValueChanged<Room3dTool> onToolChanged;
  final RoomSceneBridgeMessage onBridgeMessage;
  final VoidCallback onLoadTestScene;
  final VoidCallback onSave;
  final VoidCallback onItemDeleted;
  final ValueChanged<String?> onBuildModeChanged;
  final ValueChanged<bool> onBuildIsVirtualWallChanged;
  final ValueChanged<double> onBuildThicknessChanged;
  final ValueChanged<bool> onAngleLockEnabledChanged;
  final ValueChanged<double> onAngleStepDegreesChanged;
  final ValueChanged<String?> onPlacingOpeningKindChanged;
  final VoidCallback onFinishRoom;
  final VoidCallback onCancelBuild;
  final ValueChanged<bool> onCutawayEnabledChanged;
  final ValueChanged<bool> onWalkModeEnabledChanged;
  final ValueChanged<bool> onMeasureModeEnabledChanged;
  final ValueChanged<bool> onDimensionsEnabledChanged;
  final ValueChanged<bool> onPresentationModeEnabledChanged;
  final ValueChanged<int> onFloorSelected;
  final VoidCallback onAddFloor;
  final VoidCallback onRemoveActiveFloor;

  const _Room3dEditorScaffold({
    required this.webViewKey,
    required this.selectedTool,
    required this.selectedItemId,
    required this.selectedWallId,
    required this.selectedRoomId,
    required this.placingOpeningKind,
    required this.buildMode,
    required this.buildIsVirtualWall,
    required this.buildThicknessM,
    required this.buildPointCount,
    required this.angleLockEnabled,
    required this.angleStepDegrees,
    required this.cutawayEnabled,
    required this.walkModeEnabled,
    required this.measureModeEnabled,
    required this.dimensionsEnabled,
    required this.presentationModeEnabled,
    required this.isSaving,
    required this.saveStatusLabel,
    required this.onToolChanged,
    required this.onBridgeMessage,
    required this.onLoadTestScene,
    required this.onSave,
    required this.onItemDeleted,
    required this.onBuildModeChanged,
    required this.onBuildIsVirtualWallChanged,
    required this.onBuildThicknessChanged,
    required this.onAngleLockEnabledChanged,
    required this.onAngleStepDegreesChanged,
    required this.onPlacingOpeningKindChanged,
    required this.onFinishRoom,
    required this.onCancelBuild,
    required this.onCutawayEnabledChanged,
    required this.onWalkModeEnabledChanged,
    required this.onMeasureModeEnabledChanged,
    required this.onDimensionsEnabledChanged,
    required this.onPresentationModeEnabledChanged,
    required this.onFloorSelected,
    required this.onAddFloor,
    required this.onRemoveActiveFloor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);
    final sceneState = ref.watch(roomSceneProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: theme.dashboardContainer,
      body: Column(
        children: [
          Room3dToolbar(
            selectedTool: selectedTool,
            onToolChanged: onToolChanged,
            canUndo: sceneState.canUndo,
            canRedo: sceneState.canRedo,
            onUndo: () => ref.read(roomSceneActionsProvider).undo(),
            onRedo: () => ref.read(roomSceneActionsProvider).redo(),
            onCameraPreset: (preset) => webViewKey.currentState?.setCameraPreset(preset),
            onLoadTestScene: onLoadTestScene,
            isSaving: isSaving,
            saveStatusLabel: saveStatusLabel,
            onSave: onSave,
            cutawayEnabled: cutawayEnabled,
            onCutawayEnabledChanged: onCutawayEnabledChanged,
            walkModeEnabled: walkModeEnabled,
            onWalkModeEnabledChanged: onWalkModeEnabledChanged,
            measureModeEnabled: measureModeEnabled,
            onMeasureModeEnabledChanged: onMeasureModeEnabledChanged,
            dimensionsEnabled: dimensionsEnabled,
            onDimensionsEnabledChanged: onDimensionsEnabledChanged,
            presentationModeEnabled: presentationModeEnabled,
            onPresentationModeEnabledChanged: onPresentationModeEnabledChanged,
            // "Sąsiednie piętra" (FINAL_VISION.md §6's true floor stacking)
            // — this widget already watches `roomSceneProvider` itself
            // (`sceneState` above), so it owns this toggle end to end
            // rather than threading it through `_Room3dEditorContentState`.
            showAdjacentFloors: sceneState.showAdjacentFloors,
            onShowAdjacentFloorsChanged: (value) {
              ref.read(roomSceneProvider.notifier).setShowAdjacentFloors(value);
              ref.read(roomSceneActionsProvider).refreshViewer();
            },
            activeFloorStoryHeightM: sceneState.activeFloor?.storyHeightM ?? kDefaultStoryHeightM,
            onStoryHeightChanged: (value) => ref
                .read(roomSceneActionsProvider)
                .setFloorStoryHeight(sceneState.activeFloorIndex, value),
            onScreenshot: () => webViewKey.currentState?.captureScreenshot(),
            onGltfExport: () => webViewKey.currentState?.captureGltfExport(),
            onTopDownPlanExport: () => webViewKey.currentState?.captureTopDownPlan(),
            floorLabels: sceneState.scene?.floors.map((floor) => floor.label).toList() ?? const [],
            activeFloorIndex: sceneState.activeFloorIndex,
            onFloorSelected: onFloorSelected,
            onAddFloor: onAddFloor,
            onRemoveActiveFloor: onRemoveActiveFloor,
          ),
          Expanded(
            child: Row(
              children: [
                if (!isMobile)
                  Container(
                    width: 260,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer,
                      border: Border(right: BorderSide(color: theme.dashboardBoarder)),
                    ),
                    child: _ModePanelContent(
                      tool: selectedTool,
                      selectedWallId: selectedWallId,
                      selectedRoomId: selectedRoomId,
                      placingOpeningKind: placingOpeningKind,
                      buildMode: buildMode,
                      buildIsVirtualWall: buildIsVirtualWall,
                      buildThicknessM: buildThicknessM,
                      buildPointCount: buildPointCount,
                      angleLockEnabled: angleLockEnabled,
                      angleStepDegrees: angleStepDegrees,
                      onBuildModeChanged: onBuildModeChanged,
                      onBuildIsVirtualWallChanged: onBuildIsVirtualWallChanged,
                      onBuildThicknessChanged: onBuildThicknessChanged,
                      onAngleLockEnabledChanged: onAngleLockEnabledChanged,
                      onAngleStepDegreesChanged: onAngleStepDegreesChanged,
                      onPlacingOpeningKindChanged: onPlacingOpeningKindChanged,
                      onFinishRoom: onFinishRoom,
                      onCancelBuild: onCancelBuild,
                    ),
                  ),
                Expanded(
                  child: Room3dWebView(
                    key: webViewKey,
                    onMessage: onBridgeMessage,
                  ),
                ),
                if (!isMobile && selectedItemId != null)
                  Container(
                    width: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer,
                      border: Border(left: BorderSide(color: theme.dashboardBoarder)),
                    ),
                    child: FurnitureItemInspector(
                      key: ValueKey(selectedItemId),
                      itemId: selectedItemId!,
                      onDeleted: onItemDeleted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePanelContent extends StatelessWidget {
  final Room3dTool tool;
  final String? selectedWallId;
  final String? selectedRoomId;
  final String? placingOpeningKind;
  final String? buildMode;
  final bool buildIsVirtualWall;
  final double buildThicknessM;
  final int buildPointCount;
  final bool angleLockEnabled;
  final double angleStepDegrees;
  final ValueChanged<String?> onBuildModeChanged;
  final ValueChanged<bool> onBuildIsVirtualWallChanged;
  final ValueChanged<double> onBuildThicknessChanged;
  final ValueChanged<bool> onAngleLockEnabledChanged;
  final ValueChanged<double> onAngleStepDegreesChanged;
  final ValueChanged<String?> onPlacingOpeningKindChanged;
  final VoidCallback onFinishRoom;
  final VoidCallback onCancelBuild;

  const _ModePanelContent({
    required this.tool,
    this.selectedWallId,
    this.selectedRoomId,
    this.placingOpeningKind,
    required this.buildMode,
    required this.buildIsVirtualWall,
    required this.buildThicknessM,
    required this.buildPointCount,
    required this.angleLockEnabled,
    required this.angleStepDegrees,
    required this.onBuildModeChanged,
    required this.onBuildIsVirtualWallChanged,
    required this.onBuildThicknessChanged,
    required this.onAngleLockEnabledChanged,
    required this.onAngleStepDegreesChanged,
    required this.onPlacingOpeningKindChanged,
    required this.onFinishRoom,
    required this.onCancelBuild,
  });

  @override
  Widget build(BuildContext context) {
    return switch (tool) {
      Room3dTool.furniture => const FurnitureCatalogPanel(),
      Room3dTool.walls => WallMaterialPanel(
          key: ValueKey(selectedWallId),
          selectedWallId: selectedWallId,
          placingOpeningKind: placingOpeningKind,
          onPlacingOpeningKindChanged: onPlacingOpeningKindChanged,
        ),
      Room3dTool.floor => FloorMaterialPanel(
          key: ValueKey(selectedRoomId),
          selectedRoomId: selectedRoomId,
        ),
      Room3dTool.build => BuildPanel(
          buildMode: buildMode,
          isVirtualWall: buildIsVirtualWall,
          thicknessM: buildThicknessM,
          pointCount: buildPointCount,
          angleLockEnabled: angleLockEnabled,
          angleStepDegrees: angleStepDegrees,
          onModeChanged: onBuildModeChanged,
          onVirtualWallChanged: onBuildIsVirtualWallChanged,
          onThicknessChanged: onBuildThicknessChanged,
          onAngleLockEnabledChanged: onAngleLockEnabledChanged,
          onAngleStepDegreesChanged: onAngleStepDegreesChanged,
          onFinishRoom: onFinishRoom,
          onCancel: onCancelBuild,
        ),
    };
  }
}
