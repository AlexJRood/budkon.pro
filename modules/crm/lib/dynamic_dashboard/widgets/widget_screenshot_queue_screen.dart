import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

import '../models/dashboard_models.dart';
import '../models/screenshot_spec.dart';
import '../registry/dashboard_widget_registry.dart';
import '../services/catalog_api.dart';
import 'dashboard_widget_demo_data.dart';

const Duration _preloadDuration = Duration(seconds: 3);
const Duration _variantSettle   = Duration(milliseconds: 1500);

// ─── queue item ───────────────────────────────────────────────────────────────

enum _Status { pending, preloading, rendering, capturing, uploading, done, error }

class _QueueItem {
  final DashboardWidgetSpec spec;
  final String slug;
  _Status overallStatus = _Status.pending;
  late final Map<String, _Status>    variantStatus;
  late final Map<String, Uint8List?> images;
  String? errorMessage;

  _QueueItem({required this.spec, required this.slug}) {
    variantStatus = {for (final v in spec.screenshotSpecs) v.key: _Status.pending};
    images        = {for (final v in spec.screenshotSpecs) v.key: null};
  }

  List<WidgetScreenshotSpec> get screenshotSpecs => spec.screenshotSpecs;

  Uint8List? get thumbnail {
    final darkDesktop = screenshotSpecs
        .where((s) => s.key.startsWith('dark_desktop'))
        .firstOrNull;
    if (darkDesktop != null && images[darkDesktop.key] != null) {
      return images[darkDesktop.key];
    }
    return images.values.whereType<Uint8List>().firstOrNull;
  }

  bool get hasAnyImage => images.values.any((b) => b != null);
  bool get hasAllImages => images.values.every((b) => b != null);
}

// ─── screen ──────────────────────────────────────────────────────────────────

/// Developer-only screen. Renders each widget in all its declared screenshot
/// variants (theme × breakpoint × widget-specific settings), captures
/// transparent PNGs, and uploads them to the backend with grid-size metadata.
///
/// A 3-second pre-load window lets async providers (calendar, tasks, mail…)
/// fetch before the actual screenshots are taken.
class DashboardWidgetScreenshotQueueScreen extends ConsumerStatefulWidget {
  const DashboardWidgetScreenshotQueueScreen({super.key});

  @override
  ConsumerState<DashboardWidgetScreenshotQueueScreen> createState() => _State();
}

class _State extends ConsumerState<DashboardWidgetScreenshotQueueScreen> {
  late final List<_QueueItem> _queue;
  final _captureKey = GlobalKey();

  int                  _currentIndex  = -1;
  WidgetScreenshotSpec? _currentSpec;
  bool                 _isRunning     = false;
  bool                 _isPreloading  = false;
  late ErrorWidgetBuilder _savedErrorBuilder;

  @override
  void initState() {
    super.initState();
    final registry = ref.read(dashboardWidgetRegistryProvider);
    _queue = registry.all
        .map((s) => _QueueItem(spec: s, slug: s.type.replaceAll('_', '-')))
        .toList();

    _savedErrorBuilder = ErrorWidget.builder;
    ErrorWidget.builder = _errorFallback;
  }

  @override
  void dispose() {
    ErrorWidget.builder = _savedErrorBuilder;
    super.dispose();
  }

  static Widget _errorFallback(FlutterErrorDetails _) {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.broken_image_outlined, color: Colors.grey.shade600, size: 28),
          const SizedBox(height: 6),
          Text('Preview unavailable',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ]),
      ),
    );
  }

  // ── height ────────────────────────────────────────────────────────────────

  double _specH(DashboardWidgetSpec spec, DashboardBreakpoint bp) {
    final s  = spec.defaultSize(bp);
    final px = s.h * bp.defaultRowHeight + math.max(0, s.h - 1) * bp.defaultGap;
    return px.clamp(220.0, 720.0);
  }

  DashboardWidgetInstance _mockInstance(String type, Map<String, dynamic> settings) =>
      DashboardWidgetInstance(
          id: 'preview_$type', type: type, zoneKey: 'main', sourceKey: 'native',
          settings: settings);

  // ── queue control ─────────────────────────────────────────────────────────

  Future<void> _startAll() async {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    for (int i = 0; i < _queue.length; i++) {
      if (!_isRunning) break;
      if (_queue[i].overallStatus == _Status.done) continue;
      await _processItem(i);
    }
    setState(() => _isRunning = false);
  }

  void _stop() => setState(() => _isRunning = false);

  // ── process one widget ────────────────────────────────────────────────────

  Future<void> _processItem(int index) async {
    final item       = _queue[index];
    final savedTheme = ref.read(themeProvider);
    final specs      = item.screenshotSpecs;
    if (specs.isEmpty) return;

    ref.read(themeProvider.notifier).state = specs.first.themeMode;
    setState(() {
      _currentIndex  = index;
      _currentSpec   = specs.first;
      _isPreloading  = true;
      item.overallStatus = _Status.preloading;
      for (final s in specs) {
        item.variantStatus[s.key] = _Status.pending;
        item.images[s.key]        = null;
      }
    });
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(_preloadDuration);
    setState(() { _isPreloading = false; item.overallStatus = _Status.rendering; });

    // ── capture each variant ──────────────────────────────────────────────
    try {
      for (final spec in specs) {
        if (!_isRunning && index != _currentIndex) break;

        ref.read(themeProvider.notifier).state = spec.themeMode;
        setState(() {
          _currentSpec = spec;
          item.variantStatus[spec.key] = _Status.rendering;
        });

        await WidgetsBinding.instance.endOfFrame;
        await WidgetsBinding.instance.endOfFrame;
        await Future<void>.delayed(_variantSettle);

        setState(() => item.variantStatus[spec.key] = _Status.capturing);

        try {
          final boundary = _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
          if (boundary == null) throw Exception('RepaintBoundary not found');

          final img = await boundary.toImage(pixelRatio: 2.0);
          final bd  = await img.toByteData(format: ui.ImageByteFormat.png);
          img.dispose();

          setState(() {
            item.images[spec.key]        = bd?.buffer.asUint8List();
            item.variantStatus[spec.key] = _Status.done;
          });
        } catch (_) {
          setState(() => item.variantStatus[spec.key] = _Status.error);
        }
      }
    } finally {
      ref.read(themeProvider.notifier).state = savedTheme;
      await WidgetsBinding.instance.endOfFrame;
      setState(() => _isPreloading = false);
    }

    // ── upload all variants ───────────────────────────────────────────────
    setState(() => item.overallStatus = _Status.uploading);
    try {
      final api = ref.read(dashboardCatalogApiProvider);
      for (final v in specs) {
        final bytes = item.images[v.key];
        if (bytes == null) continue;
        final gridSize = item.spec.defaultSize(v.breakpoint);
        await api.uploadPreviewImage(
          item.slug, bytes,
          variant: v.key,
          label: v.label,
          gridW: gridSize.w,
          gridH: gridSize.h,
        );
      }
      setState(() => item.overallStatus = _Status.done);
    } catch (e) {
      setState(() {
        item.overallStatus = _Status.error;
        item.errorMessage  = 'Upload: $e';
      });
    }
  }

  // ── save helpers ──────────────────────────────────────────────────────────

  Future<void> _saveVariant(_QueueItem item, WidgetScreenshotSpec v) async {
    final bytes = item.images[v.key];
    if (bytes == null) return;

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save ${v.label}',
      fileName: '${item.slug}_${v.key}.png',
      type: FileType.custom,
      allowedExtensions: ['png'],
    );
    if (path == null || !mounted) return;

    await File(path).writeAsBytes(bytes, flush: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Saved: $path'),
            action: SnackBarAction(label: 'OK', onPressed: () {})),
      );
    }
  }

  Future<void> _saveAll(_QueueItem item) async {
    if (!item.hasAnyImage) return;

    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose folder for ${item.slug} previews',
    );
    if (dir == null || !mounted) return;

    int saved = 0;
    for (final v in item.screenshotSpecs) {
      final bytes = item.images[v.key];
      if (bytes == null) continue;
      await File('$dir/${item.slug}_${v.key}.png').writeAsBytes(bytes, flush: true);
      saved++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Saved $saved files to $dir'),
            action: SnackBarAction(label: 'OK', onPressed: () {})),
      );
    }
  }

  // ── render target (live preview + capture source) ─────────────────────────

  Widget _buildRenderTarget() {
    final spec = _currentSpec;
    if (_currentIndex < 0 || _currentIndex >= _queue.length || spec == null) {
      return const SizedBox(width: 640.0, height: 360);
    }
    final item = _queue[_currentIndex];
    final h    = _specH(item.spec, spec.breakpoint);

    return RepaintBoundary(
      key: _captureKey,
      child: Material(
        // Transparent so the captured PNG has no extra background — only the
        // widget's own rendering. The wrapping Container (in build()) shows
        // bgColor for live preview but is outside the RepaintBoundary.
        color: Colors.transparent,
        child: ProviderScope(
          // Injects demo data so every widget renders with realistic sample
          // content. Non-overridden providers (including themeProvider) fall
          // through to the parent scope so global theme mutations propagate.
          overrides: buildDemoProviderOverrides(),
          child: Consumer(
            builder: (ctx, demoRef, _) => SizedBox(
              width:  spec.renderWidth,
              height: h,
              child: item.spec.build(
                ctx, demoRef,
                _mockInstance(item.spec.type, spec.settings),
                spec.breakpoint, false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final doneCount  = _queue.where((e) => e.overallStatus == _Status.done).length;
    final currentBg  = _currentSpec?.bgColor ?? theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Widget Previews  ($doneCount/${_queue.length})'),
        actions: [
          if (!_isRunning)
            FilledButton.icon(
              onPressed: _startAll,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start all'),
            )
          else
            FilledButton.icon(
              onPressed: _stop,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Stop'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── queue list ─────────────────────────────────────────────────
          SizedBox(
            width: 380,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _queue.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
              itemBuilder: (_, i) => _buildQueueTile(_queue[i], i),
            ),
          ),
          const VerticalDivider(width: 1),

          // ── preview panel ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentIndex >= 0) ...[
                    Row(children: [
                      Text(
                        _queue[_currentIndex].spec.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      if (_currentSpec != null) _variantChip(_currentSpec!),
                      if (_isPreloading) ...[
                        const SizedBox(width: 8),
                        _badge('Loading data…', Colors.blue),
                      ],
                    ]),
                    Text(_queue[_currentIndex].slug,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline)),
                    const SizedBox(height: 12),
                  ],

                  // Live render — Container bg is for UI only (outside RepaintBoundary)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                      color: currentBg,
                    ),
                    clipBehavior: Clip.hardEdge,
                    padding: const EdgeInsets.all(16),
                    child: Center(child: _buildRenderTarget()),
                  ),

                  // ── dynamic variant grid ──────────────────────────────
                  if (_currentIndex >= 0 &&
                      _queue[_currentIndex].hasAnyImage) ...[
                    const SizedBox(height: 20),
                    Row(children: [
                      Text('Generated previews',
                          style: theme.textTheme.labelMedium),
                      const Spacer(),
                      if (_queue[_currentIndex].hasAllImages)
                        TextButton.icon(
                          onPressed: () => _saveAll(_queue[_currentIndex]),
                          icon: const Icon(Icons.folder_zip_rounded, size: 16),
                          label: Text(
                              'Save all ${_queue[_currentIndex].screenshotSpecs.length}'),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    _buildVariantGrid(_queue[_currentIndex]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2-column grid — any number of rows driven by the widget's screenshotSpecs.
  Widget _buildVariantGrid(_QueueItem item) {
    final specs = item.screenshotSpecs;
    final rows  = <List<WidgetScreenshotSpec>>[];
    for (int i = 0; i < specs.length; i += 2) {
      rows.add(specs.sublist(i, math.min(i + 2, specs.length)));
    }
    return Column(
      children: rows.map((pair) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: pair.map((v) => Expanded(child: _buildVariantCell(item, v))).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildVariantCell(_QueueItem item, WidgetScreenshotSpec v) {
    final theme = Theme.of(context);
    final bytes = item.images[v.key];

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      decoration: BoxDecoration(
        color: v.bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: v.isLightUi
                  ? Colors.black.withAlpha(12)
                  : Colors.white.withAlpha(12),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  v.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: v.isLightUi ? Colors.black54 : Colors.white60,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (bytes != null)
                GestureDetector(
                  onTap: () => _saveVariant(item, v),
                  child: Tooltip(
                    message: 'Save ${v.label}',
                    child: Icon(
                      Icons.download_rounded,
                      size: 16,
                      color: v.isLightUi ? Colors.black45 : Colors.white54,
                    ),
                  ),
                ),
            ]),
          ),
          // Image or placeholder
          if (bytes != null)
            Image.memory(bytes, fit: BoxFit.fitWidth)
          else
            SizedBox(
              height: 120,
              child: Center(
                child: Icon(Icons.hourglass_empty_rounded,
                    color: v.isLightUi ? Colors.black26 : Colors.white24, size: 24),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQueueTile(_QueueItem item, int index) {
    final isActive      = index == _currentIndex;
    final (icon, color) = _indicator(item.overallStatus);
    final thumb         = item.thumbnail;

    return ListTile(
      dense: true,
      selected: isActive,
      leading: Icon(item.spec.icon, size: 20),
      title: Text(item.spec.title,
          style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
      subtitle: Row(children: [
        for (final v in item.screenshotSpecs)
          _dot(item.variantStatus[v.key] ?? _Status.pending, v),
      ]),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (thumb != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.memory(thumb, width: 56, height: 28, fit: BoxFit.cover),
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: const Icon(Icons.folder_zip_rounded, size: 16),
            tooltip: 'Save all',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => _saveAll(item),
          ),
        ],
        Icon(icon, color: color, size: 18),
      ]),
      onTap: _isRunning ? null : () => _processItem(index),
    );
  }

  Widget _dot(_Status s, WidgetScreenshotSpec v) {
    final (_, color) = _indicator(s);
    return Tooltip(
      message: v.label,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: v.isLightUi ? Border.all(color: Colors.white24, width: 0.5) : null,
          ),
        ),
      ),
    );
  }

  Widget _variantChip(WidgetScreenshotSpec v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: v.isLightUi ? Colors.amber.withAlpha(40) : Colors.indigo.withAlpha(60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: v.isLightUi
                ? Colors.amber.withAlpha(120)
                : Colors.indigo.withAlpha(120)),
      ),
      child: Text(v.label,
          style: TextStyle(
            fontSize: 11,
            color: v.isLightUi ? Colors.amber.shade700 : Colors.indigo.shade300,
          )),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  static (IconData, Color) _indicator(_Status s) => switch (s) {
        _Status.pending    => (Icons.hourglass_empty_rounded, Colors.grey),
        _Status.preloading => (Icons.downloading_rounded, Colors.lightBlue.shade300),
        _Status.rendering  => (Icons.visibility_rounded, Colors.orange),
        _Status.capturing  => (Icons.camera_alt_rounded, Colors.lightBlue),
        _Status.uploading  => (Icons.cloud_upload_rounded, Colors.blue),
        _Status.done       => (Icons.check_circle_rounded, Colors.green),
        _Status.error      => (Icons.error_rounded, Colors.red),
      };
}
