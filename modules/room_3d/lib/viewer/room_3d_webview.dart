/// Hosts the three.js viewer and implements the Flutter<->JS bridge
/// protocol from docs/sims_mode/ARCHITECTURE.md section 6. The three.js
/// scene itself lives in `assets/viewer/` (scene.js + a locally-bundled
/// three.js build, no CDN dependency).
///
/// Served over `http://localhost` via the bundled `InAppLocalhostServer`,
/// NOT loaded directly as `file://` (via `initialFile`) — Chromium/WebView2
/// blocks `<script type="module">` (so scene.js's `import`s) on a `file://`
/// origin. The page itself still loads fine in that case, so this failure
/// mode is silent: no error anywhere, `ready` just never fires and the
/// viewport stays blank. Found this the hard way running on real Windows.
///
/// Uses `flutter_inappwebview`, NOT `webview_flutter` — the latter has no
/// Windows/Linux desktop platform implementation (Android/iOS/macOS/Web
/// only) and crashes immediately on a Windows build
/// ("WebViewPlatform.instance != null"). flutter_inappwebview officially
/// supports Windows and is already this project's convention for webviews
/// elsewhere (floor_plan, mail/html_email_view.dart, network_monitoring).
///
/// Wall/floor material rendering is color-only for now (`colorHex` below) -
/// scene.js just tints the wall mesh. Real texture loading from
/// surface_materials' `textureUrl` is Faza 2 work, once that catalog has
/// real assets.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../model/room_scene.dart';

typedef RoomSceneBridgeMessage = void Function(
  String type,
  Map<String, dynamic> payload,
);

class Room3dWebView extends StatefulWidget {
  final RoomSceneBridgeMessage? onMessage;

  const Room3dWebView({super.key, this.onMessage});

  @override
  State<Room3dWebView> createState() => Room3dWebViewState();
}

class Room3dWebViewState extends State<Room3dWebView> {
  // Chromium/WebView2 blocks `<script type="module">` (and therefore
  // scene.js's `import` statements) when the page is loaded from a `file://`
  // origin — the page itself loads fine, but the module script silently
  // never executes, so `ready` never fires and the viewport stays blank
  // with no error surfaced anywhere. `initialFile` loads via file://, so it
  // hits exactly this. Fix: serve the asset directory over a real
  // `http://localhost` origin via flutter_inappwebview's bundled
  // `InAppLocalhostServer` (pure Dart `HttpServer` + `rootBundle.load`,
  // works on desktop) instead.
  static const _localhostPort = 8734;
  final InAppLocalhostServer _localhostServer = InAppLocalhostServer(
    documentRoot: 'packages/room_3d/assets/viewer',
    port: _localhostPort,
    shared: true, // tolerate a stale bind surviving a hot-restart
  );
  bool _serverReady = false;

  InAppWebViewController? _controller;
  bool _ready = false;

  /// Whether the JS-side scene has finished initializing and can accept
  /// commands. Callers that need to `loadScene` right after this widget
  /// mounts (e.g. auto-loading a saved project) should check this first —
  /// `_send` silently no-ops before `ready`, so a call made too early is
  /// just lost, not queued.
  bool get isReady => _ready;

  @override
  void initState() {
    super.initState();
    _localhostServer.start().then((_) {
      if (mounted) setState(() => _serverReady = true);
    });
  }

  @override
  void dispose() {
    _localhostServer.close();
    super.dispose();
  }

  void _handleBridgeMessage(List<dynamic> args) {
    if (args.isEmpty) return;

    try {
      final raw = args.first;
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) return;

      final type = decoded['type']?.toString() ?? '';
      final payload = Map<String, dynamic>.from(decoded['payload'] ?? {});

      if (type == 'ready') {
        _ready = true;
      }

      widget.onMessage?.call(type, payload);
    } catch (_) {
      // Malformed bridge message — ignore rather than crash the viewer.
    }
  }

  Future<void> _send(String type, Map<String, dynamic> payload) async {
    if (!_ready || _controller == null) return;

    final envelope = jsonEncode({'type': type, 'payload': payload});
    await _controller!.evaluateJavascript(
      source: 'window.onFlutterMessage && window.onFlutterMessage($envelope);',
    );
  }

  /// Generic passthrough — lets `RoomSceneActions.onCommand` (whose
  /// (type, payload) shape already mirrors the JS bridge envelope) forward
  /// straight to the viewer without a matching typed method for every
  /// command. The typed methods below remain for call sites that want
  /// compile-time-checked parameters (e.g. the initial `loadScene`).
  Future<void> sendCommand(String type, Map<String, dynamic> payload) =>
      _send(type, payload);

  Future<void> placeItem(RoomPlacedItem item) => _send('placeItem', item.toJson());

  Future<void> moveItem({
    required String id,
    RoomPoint3? position,
    double? rotationDeg,
  }) =>
      _send('moveItem', {
        'id': id,
        if (position != null) 'position': position.toJson(),
        if (rotationDeg != null) 'rotation_deg': rotationDeg,
      });

  Future<void> removeItem(String id) => _send('removeItem', {'id': id});

  Future<void> setWallZoneMaterial({
    required String wallId,
    String? zoneId,
    required String materialId,
    String? colorHex,
  }) =>
      _send('setWallZoneMaterial', {
        'wall_id': wallId,
        'zone_id': zoneId,
        'material_id': materialId,
        if (colorHex != null) 'color': colorHex,
      });

  Future<void> previewMaterial({
    required String wallId,
    String? zoneId,
    required String materialId,
    String? colorHex,
  }) =>
      _send('previewMaterial', {
        'wall_id': wallId,
        'zone_id': zoneId,
        'material_id': materialId,
        if (colorHex != null) 'color': colorHex,
      });

  Future<void> setCameraPreset(String preset) =>
      _send('setCameraPreset', {'preset': preset});

  Future<void> setSelection(String? id) => _send('setSelection', {'id': id});

  /// `mode` is `'wall'`, `'room'`, `'stair'`, or `null` to leave build mode entirely.
  Future<void> setBuildMode(String? mode, {bool isVirtual = false, double? thicknessM}) =>
      _send('setBuildMode', {
        'mode': mode,
        'is_virtual': isVirtual,
        if (thicknessM != null) 'thickness_m': thicknessM,
      });

  Future<void> cancelBuild() => _send('cancelBuild', {});

  Future<void> finishRoomDraw() => _send('finishRoomDraw', {});

  Future<void> setCutawayEnabled(bool enabled) =>
      _send('setCutawayEnabled', {'enabled': enabled});

  Future<void> setWalkMode(bool enabled) => _send('setWalkMode', {'enabled': enabled});

  Future<void> setMeasureMode(bool enabled) => _send('setMeasureMode', {'enabled': enabled});

  /// Triggers a PNG capture of the current viewport — the viewer replies
  /// asynchronously with a `screenshotCaptured` bridge message carrying a
  /// data URL (see `room_3d_editor_page.dart`'s handler for the save-to-disk
  /// side, `scene.js`'s `captureScreenshot()` for the render side).
  Future<void> captureScreenshot() => _send('captureScreenshot', {});

  /// Triggers a binary glTF (.glb) export of the active floor's geometry —
  /// the viewer replies with a `gltfExportReady` bridge message carrying
  /// base64-encoded bytes (see `room_3d_editor_page.dart`'s handler for the
  /// save-to-disk side, `scene.js`'s `captureGltfExport()` for the export).
  Future<void> captureGltfExport() => _send('captureGltfExport', {});

  /// Triggers a top-down technical-plan PNG capture (FINAL_VISION.md §7.4's
  /// "rzut z góry z wymiarami") — the viewer replies with a
  /// `topDownPlanCaptured` bridge message carrying a data URL. Unlike
  /// [captureScreenshot], this doesn't just grab the current view: `scene.js`
  /// temporarily swaps in a top-down orthographic camera and composites wall
  /// length labels directly onto the captured pixels (an HTML overlay like
  /// the live "Wymiary" toggle's `<div>`s never shows up in `toDataURL()`).
  Future<void> captureTopDownPlan() => _send('captureTopDownPlan', {});

  Future<void> setDimensionsEnabled(bool enabled) =>
      _send('setDimensionsEnabled', {'enabled': enabled});

  /// "Tryb prezentacyjny" (FINAL_VISION.md §7.3) — soft shadows + a warmer
  /// fill light, off by default since it's noticeably more expensive than
  /// the flat working-mode lighting.
  Future<void> setPresentationModeEnabled(bool enabled) =>
      _send('setPresentationModeEnabled', {'enabled': enabled});

  /// Angle-lock while drawing in Buduj (FINAL_VISION.md §4's "angle-lock do
  /// dowolnego kroku stopni" item) — ported from floor_plan's own toggle +
  /// 15/30/45/90° step picker convention.
  Future<void> setAngleLock({required bool enabled, required double stepDegrees}) =>
      _send('setAngleLock', {'enabled': enabled, 'step_degrees': stepDegrees});

  /// Arms/disarms placing a new door/window opening (FINAL_VISION.md §4's
  /// last Buduj debt item) — `kind` is `'door'`, `'window'`, or `null` to
  /// cancel. The viewer replies with an `openingPlaced` bridge message once
  /// the user actually clicks the selected wall.
  Future<void> setPlacingOpening(String? kind) => _send('setPlacingOpening', {'kind': kind});

  @override
  Widget build(BuildContext context) {
    if (!_serverReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri('http://localhost:$_localhostPort/index.html'),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: false,
        supportZoom: false,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        controller.addJavaScriptHandler(
          handlerName: 'roomSceneBridge',
          callback: (args) {
            _handleBridgeMessage(args);
            return null;
          },
        );
      },
    );
  }
}
