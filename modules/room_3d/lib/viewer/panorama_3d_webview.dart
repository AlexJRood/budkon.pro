/// Minimal 360° equirectangular panorama viewer, sharing only the
/// WebView+three.js plumbing pattern established by [Room3dWebView] (see
/// that file's doc comment for why flutter_inappwebview, not
/// webview_flutter, and why it's served over http://localhost via
/// InAppLocalhostServer rather than loaded as file:// — Chromium/WebView2
/// silently refuses to execute `<script type="module">` on a file://
/// origin, which panorama_scene.js uses for its three.js imports same as
/// scene.js does). It is intentionally NOT built on RoomScene/furniture
/// editing state — the panorama_scene.js asset is a standalone three.js
/// scene (a single textured sphere), since there's no skybox/background
/// concept in scene.js to extend.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Panorama3dWebView extends StatefulWidget {
  final String imageUrl;
  final void Function(String type, Map<String, dynamic> payload)? onMessage;

  const Panorama3dWebView({super.key, required this.imageUrl, this.onMessage});

  @override
  State<Panorama3dWebView> createState() => _Panorama3dWebViewState();
}

class _Panorama3dWebViewState extends State<Panorama3dWebView> {
  // Different port from Room3dWebView's 8734 so both can be mounted at once
  // without a bind collision.
  static const _localhostPort = 8735;
  final InAppLocalhostServer _localhostServer = InAppLocalhostServer(
    documentRoot: 'packages/room_3d/assets/viewer',
    port: _localhostPort,
    shared: true,
  );
  bool _serverReady = false;

  InAppWebViewController? _controller;
  bool _ready = false;

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

  @override
  void didUpdateWidget(covariant Panorama3dWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl && _ready) {
      _loadPanorama();
    }
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
        _loadPanorama();
      }

      widget.onMessage?.call(type, payload);
    } catch (_) {
      // Malformed bridge message — ignore rather than crash the viewer.
    }
  }

  Future<void> _loadPanorama() async {
    if (_controller == null) return;
    final envelope = jsonEncode({
      'type': 'loadPanorama',
      'payload': {'url': widget.imageUrl},
    });
    await _controller!.evaluateJavascript(
      source: 'window.onFlutterMessage && window.onFlutterMessage($envelope);',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_serverReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri('http://localhost:$_localhostPort/panorama.html'),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: false,
        supportZoom: false,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        controller.addJavaScriptHandler(
          handlerName: 'panoramaBridge',
          callback: (args) {
            _handleBridgeMessage(args);
            return null;
          },
        );
      },
    );
  }
}
