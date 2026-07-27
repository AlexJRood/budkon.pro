part of 'floor_plan_canvas.dart';

/// Service for exporting a [FloorPlanDocument] to PNG, JPG, or PDF.
///
/// This class is a `part` of the canvas library so it can access
/// [FloorPlanPainterStyle], [FloorPlanExportSettings], [FloorPlanExportFormat],
/// and [_StyledFloorPlanExportPainter] without any circular-import issues.
/// It intentionally holds no Flutter state — all state comes from constructor
/// parameters.
class FloorPlanExportService {
  final FloorPlanDocument document;
  final FloorPlanBackgroundImage? backgroundImage;

  const FloorPlanExportService({
    required this.document,
    required this.backgroundImage,
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Public instance methods
  // ────────────────────────────────────────────────────────────────────────────

  Future<Uint8List> buildBytes(FloorPlanExportSettings settings) async {
    final pngBytes = await renderToPng(settings);

    switch (settings.format) {
      case FloorPlanExportFormat.png:
        return pngBytes;

      case FloorPlanExportFormat.jpg:
        final decoded = img.decodePng(pngBytes);

        if (decoded == null) {
          throw Exception('failed_to_convert_png_to_jpg');
        }

        return Uint8List.fromList(
          img.encodeJpg(decoded, quality: 92),
        );

      case FloorPlanExportFormat.webp:
        throw UnsupportedError('webp_export_requires_separate_encoder');

      case FloorPlanExportFormat.pdf:
        return buildPdf(pngBytes);
    }
  }

  Future<Uint8List> renderToPng(FloorPlanExportSettings settings) async {
    final exportBounds = resolveExportBounds(settings);
    final style = FloorPlanExportService.buildPainterStyle(settings);

    final logicalSize = Size(
      math.max(1, exportBounds.width),
      math.max(1, exportBounds.height),
    );

    final safeRatio = FloorPlanExportService.safePixelRatio(
      requested: settings.pixelRatio,
      logicalSize: logicalSize,
    );

    final outputWidth = math.max(
      1,
      (logicalSize.width * safeRatio).round(),
    );

    final outputHeight = math.max(
      1,
      (logicalSize.height * safeRatio).round(),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.scale(safeRatio);

    final backgroundPaint = Paint()
      ..color = style.backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Offset.zero & logicalSize,
      backgroundPaint,
    );

    canvas.save();
    canvas.translate(-exportBounds.left, -exportBounds.top);

    if (settings.showBackgroundImage) {
      await _paintBackgroundImage(canvas);
    }

    _StyledFloorPlanExportPainter(
      document: document,
      style: style,
      showCornerAngles: settings.showCornerAngles,
      showRoomLabels: settings.showRoomLabels,
      showRoomAreas: settings.showRoomAreas,
    ).paint(
      canvas,
      Size(
        document.canvas.width,
        document.canvas.height,
      ),
    );

    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(outputWidth, outputHeight);

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('failed_to_render_image');
    }

    return byteData.buffer.asUint8List();
  }

  Rect resolveExportBounds(FloorPlanExportSettings settings) {
    final fullCanvas = Rect.fromLTWH(
      0,
      0,
      document.canvas.width,
      document.canvas.height,
    );

    if (settings.boundsMode == FloorPlanExportBoundsMode.fullCanvas) {
      return fullCanvas;
    }

    final contentBounds = _calculateContentBounds(settings);

    if (contentBounds == null) {
      return fullCanvas;
    }

    final margin = settings.marginPx.clamp(0.0, 1000.0).toDouble();
    final expanded = contentBounds.inflate(margin);

    final left = expanded.left.clamp(0.0, fullCanvas.right).toDouble();
    final top = expanded.top.clamp(0.0, fullCanvas.bottom).toDouble();
    final right = expanded.right.clamp(0.0, fullCanvas.right).toDouble();
    final bottom = expanded.bottom.clamp(0.0, fullCanvas.bottom).toDouble();

    final rect = Rect.fromLTRB(
      left,
      top,
      math.max(left + 1, right),
      math.max(top + 1, bottom),
    );

    if (rect.width < 10 || rect.height < 10) {
      return fullCanvas;
    }

    return rect;
  }

  Future<Uint8List> buildPdf(Uint8List pngBytes) async {
    final pdfDocument = pw.Document();

    final isLandscape = document.canvas.width >= document.canvas.height;
    final pageFormat =
        isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    final image = pw.MemoryImage(pngBytes);

    pdfDocument.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(18),
        build: (context) {
          return pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          );
        },
      ),
    );

    return pdfDocument.save();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Private instance helpers
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> _paintBackgroundImage(Canvas canvas) async {
    final background = backgroundImage;
    if (background == null) return;

    final codec = await ui.instantiateImageCodec(background.bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final center = Offset(
      background.x + background.width / 2,
      background.y + background.height / 2,
    );

    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: background.width,
      height: background.height,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(background.rotationDeg * math.pi / 180.0);

    final opacity = background.opacity.clamp(0.0, 1.0).toDouble();

    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true
      ..color = Colors.white.withOpacity(opacity);

    canvas.drawImageRect(image, src, dst, paint);
    canvas.restore();
  }

  Rect? _calculateContentBounds(FloorPlanExportSettings settings) {
    Rect? result;

    void addPoint(Offset point) {
      final rect = Rect.fromCircle(center: point, radius: 1);
      result = result == null ? rect : result!.expandToInclude(rect);
    }

    void addRect(Rect rect) {
      result = result == null ? rect : result!.expandToInclude(rect);
    }

    for (final wall in document.walls) {
      final start = wall.start.toOffset();
      final end = wall.end.toOffset();

      addPoint(start);
      addPoint(end);

      final thickness = _wallThicknessPx(wall);

      addRect(
        Rect.fromPoints(start, end).inflate(thickness / 2 + 80),
      );
    }

    for (final room in document.rooms) {
      for (final point in room.points) {
        addPoint(point.toOffset());
      }
    }

    if (settings.showAssets) {
      for (final asset in document.assets) {
        addRect(_assetCanvasRect(asset).inflate(80));
      }
    }

    if (settings.showOpenings) {
      for (final door in document.doors) {
        final wallId = door['wall_id']?.toString();
        if (wallId == null) continue;

        final wall = _findWallById(wallId);
        if (wall == null) continue;

        final center = _openingCenter(door, wall);
        if (center == null) continue;

        addRect(Rect.fromCircle(center: center, radius: 120));
      }

      for (final window in document.windows) {
        final wallId = window['wall_id']?.toString();
        if (wallId == null) continue;

        final wall = _findWallById(wallId);
        if (wall == null) continue;

        final center = _openingCenter(window, wall);
        if (center == null) continue;

        addRect(Rect.fromCircle(center: center, radius: 120));
      }
    }

    final background = backgroundImage;
    if (background != null && settings.showBackgroundImage) {
      addRect(
        Rect.fromLTWH(
          background.x,
          background.y,
          background.width,
          background.height,
        ),
      );
    }

    return result;
  }

  FloorWall? _findWallById(String id) {
    for (final wall in document.walls) {
      if (wall.id == id) return wall;
    }
    return null;
  }

  Offset? _openingCenter(Map<String, dynamic> item, FloorWall wall) {
    final start = wall.start.toOffset();
    final end = wall.end.toOffset();
    final vector = end - start;

    final position = (item['position'] as num?)?.toDouble() ?? 0.5;

    return Offset(
      start.dx + vector.dx * position,
      start.dy + vector.dy * position,
    );
  }

  Rect _assetCanvasRect(FloorPlanAsset asset) {
    final widthPx = asset.widthM * document.scale.pixelsPerMeter;
    final depthPx = asset.depthM * document.scale.pixelsPerMeter;
    final center = asset.position.toOffset();

    return Rect.fromCenter(
      center: center,
      width: widthPx,
      height: depthPx,
    );
  }

  double _wallThicknessPx(FloorWall wall) {
    if (wall.isVirtual) return 2.0;

    final thicknessM = wall.thickness / 100.0;
    final px = thicknessM * document.scale.pixelsPerMeter;

    return px.clamp(2.0, 120.0).toDouble();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Public static helpers
  // ────────────────────────────────────────────────────────────────────────────

  static FloorPlanPainterStyle buildPainterStyle(
    FloorPlanExportSettings settings,
  ) {
    return FloorPlanPainterStyle(
      backgroundColor: hexToColor(settings.backgroundColorHex),
      gridColor: hexToColor(settings.gridColorHex),
      wallColor: hexToColor(settings.wallColorHex),
      virtualWallColor: hexToColor(settings.virtualWallColorHex),
      openingColor: hexToColor(settings.openingColorHex),
      assetFillColor: hexToColor(settings.assetFillColorHex),
      assetStrokeColor: hexToColor(settings.assetStrokeColorHex),
      roomFillColor: hexToColor(settings.roomFillColorHex),
      roomHighlightColor: hexToColor(settings.roomHighlightColorHex),
      labelColor: hexToColor(settings.labelColorHex),
      roomFillOpacity: settings.roomFillOpacity.clamp(0.0, 1.0).toDouble(),
      roomHighlightOpacity:
          settings.roomHighlightOpacity.clamp(0.0, 1.0).toDouble(),
      showGrid: settings.showGrid,
      showWallDimensions: settings.showWallDimensions,
      showRoomFill: settings.showRoomFill,
      highlightRooms: settings.highlightRooms,
      showAssets: settings.showAssets,
      showOpenings: settings.showOpenings,
    );
  }

  /// Applies a colour preset to [settings] for the given [mode].
  ///
  /// [appTheme] must expose the same fields as the Riverpod `themeColorsProvider`
  /// value (i.e. `dashboardContainer`, `dashboardBoarder`, `textColor`,
  /// `themeColor`, `adPopBackground`). Pass the result of
  /// `ProviderScope.containerOf(context, listen: false).read(themeColorsProvider)`
  /// as [appTheme].
  static FloorPlanExportSettings applyThemePreset(
    FloorPlanExportSettings settings,
    FloorPlanExportThemeMode mode,
    dynamic appTheme,
  ) {
    switch (mode) {
      case FloorPlanExportThemeMode.current:
        return settings.copyWith(
          themeMode: mode,
          backgroundColorHex: colorToHex(appTheme.dashboardContainer as Color),
          gridColorHex: colorToHex(appTheme.dashboardBoarder as Color),
          wallColorHex: colorToHex(appTheme.textColor as Color),
          virtualWallColorHex: colorToHex(
            (appTheme.textColor as Color).withAlpha(160),
          ),
          openingColorHex: colorToHex(appTheme.themeColor as Color),
          assetFillColorHex: colorToHex(appTheme.adPopBackground as Color),
          assetStrokeColorHex: colorToHex(appTheme.textColor as Color),
          roomFillColorHex: colorToHex(appTheme.themeColor as Color),
          roomHighlightColorHex: colorToHex(appTheme.themeColor as Color),
          labelColorHex: colorToHex(appTheme.textColor as Color),
          roomFillOpacity: 0.16,
          roomHighlightOpacity: 0.26,
        );

      case FloorPlanExportThemeMode.white:
        return settings.copyWith(
          themeMode: mode,
          backgroundColorHex: '#FFFFFF',
          gridColorHex: '#E5E7EB',
          wallColorHex: '#111827',
          virtualWallColorHex: '#6B7280',
          openingColorHex: '#0891B2',
          assetFillColorHex: '#F8FAFC',
          assetStrokeColorHex: '#1F2937',
          roomFillColorHex: '#A78BFA',
          roomHighlightColorHex: '#7C3AED',
          labelColorHex: '#111827',
          roomFillOpacity: 0.14,
          roomHighlightOpacity: 0.20,
        );

      case FloorPlanExportThemeMode.dark:
        return settings.copyWith(
          themeMode: mode,
          backgroundColorHex: '#111827',
          gridColorHex: '#374151',
          wallColorHex: '#F9FAFB',
          virtualWallColorHex: '#9CA3AF',
          openingColorHex: '#22D3EE',
          assetFillColorHex: '#1F2937',
          assetStrokeColorHex: '#E5E7EB',
          roomFillColorHex: '#8B5CF6',
          roomHighlightColorHex: '#A855F7',
          labelColorHex: '#FFFFFF',
          roomFillOpacity: 0.18,
          roomHighlightOpacity: 0.30,
        );

      case FloorPlanExportThemeMode.blueprint:
        return settings.copyWith(
          themeMode: mode,
          backgroundColorHex: '#071426',
          gridColorHex: '#1E3A5F',
          wallColorHex: '#E0F2FE',
          virtualWallColorHex: '#38BDF8',
          openingColorHex: '#22D3EE',
          assetFillColorHex: '#0F243A',
          assetStrokeColorHex: '#BAE6FD',
          roomFillColorHex: '#2563EB',
          roomHighlightColorHex: '#38BDF8',
          labelColorHex: '#F0F9FF',
          roomFillOpacity: 0.14,
          roomHighlightOpacity: 0.25,
        );
    }
  }

  static Future<String?> saveFile({
    required Uint8List bytes,
    required FloorPlanExportFormat format,
  }) async {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final name = safeFileName('floor_plan_$timestamp');

    final savedPath = await FileSaver.instance.saveAs(
      name: name,
      bytes: bytes,
      fileExtension: format.extension,
      mimeType: MimeType.other,
      customMimeType: mimeType(format),
    );

    if (savedPath == null || savedPath.trim().isEmpty) {
      throw Exception('Eksport został anulowany.');
    }

    return savedPath;
  }

  static String safeFileName(String value) {
    return value
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  static String mimeType(FloorPlanExportFormat format) {
    switch (format) {
      case FloorPlanExportFormat.png:
        return 'image/png';
      case FloorPlanExportFormat.jpg:
        return 'image/jpeg';
      case FloorPlanExportFormat.webp:
        return 'image/webp';
      case FloorPlanExportFormat.pdf:
        return 'application/pdf';
    }
  }

  static double safePixelRatio({
    required double requested,
    required Size logicalSize,
  }) {
    const maxSide = 8192.0;

    final widthRatio = maxSide / logicalSize.width;
    final heightRatio = maxSide / logicalSize.height;

    final safe = math.min(
      requested,
      math.min(widthRatio, heightRatio),
    );

    return safe.clamp(0.1, requested).toDouble();
  }

  static String formatAreaLabel(double area) {
    return '${area.toStringAsFixed(2)} m²';
  }

  static String colorToHex(Color color) {
    final value = color.value.toRadixString(16).padLeft(8, '0').substring(2);
    return '#${value.toUpperCase()}';
  }

  static Color hexToColor(String value) {
    var hex = value.trim();

    if (!hex.startsWith('#')) {
      hex = '#$hex';
    }

    if (hex.length == 4) {
      final r = hex[1];
      final g = hex[2];
      final b = hex[3];
      hex = '#$r$r$g$g$b$b';
    }

    try {
      if (hex.length == 7) {
        return Color(int.parse(hex.replaceFirst('#', '0xFF')));
      }
    } catch (_) {}

    return Colors.black;
  }
}
