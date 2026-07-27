part of 'floor_plan_canvas.dart';

extension _FloorPlanCanvasExport on _FloorPlanCanvasState {
  FloorPlanExportService get _exportService => FloorPlanExportService(
        document: widget.document,
        backgroundImage: widget.backgroundImage,
      );

  Future<void> _exportPlan(FloorPlanExportFormat format) async {
    _hideContextMenu();
    _hideLengthEditor(commit: true);
    _hideAngleEditor(commit: true);
    _hideRoomNameEditor(commit: true);

    final service = _exportService;

    final initial = FloorPlanExportSettings.initial(
      format: format,
      showCornerAngles: _cornerAnglesVisible,
      showRoomLabels: _roomLabelsVisible,
      showRoomAreas: _roomAreasVisible,
    );

    final appTheme = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(themeColorsProvider);

    final settings = await _showExportSettingsDialog(
      FloorPlanExportService.applyThemePreset(
        initial,
        FloorPlanExportThemeMode.current,
        appTheme,
      ),
    );

    if (settings == null) return;

    try {
      final bytes = await service.buildBytes(settings);

      final savedPath = await FloorPlanExportService.saveFile(
        bytes: bytes,
        format: settings.format,
      );

      if (!mounted) return;

      _showExportSuccessSnackBar(
        format: settings.format,
        savedPath: savedPath,
      );
    } catch (e, st) {
      debugPrint('Export failed: $e\n$st');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('failed_to_export_plan'.tr)),
      );
    }
  }

  void _showExportSuccessSnackBar({
    required FloorPlanExportFormat format,
    required String? savedPath,
  }) {
    final canReveal = savedPath != null && savedPath.trim().isNotEmpty;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          canReveal
              ? '${'plan_exported_as'.tr} ${format.label}.'
              : '${'plan_exported_as'.tr}  ${format.label}.',
        ),
        action: canReveal
            ? SnackBarAction(
                label: 'show_button'.tr,
                onPressed: () async {
                  final opened = await openExportFileLocation(savedPath);

                  if (!mounted) return;

                  if (!opened) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'failed_to_open_file_location'.tr,
                        ),
                      ),
                    );
                  }
                },
              )
            : null,
      ),
    );
  }

  Future<FloorPlanExportSettings?> _showExportSettingsDialog(
    FloorPlanExportSettings initialSettings,
  ) async {
    var settings = initialSettings;

    return showDialog<FloorPlanExportSettings>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = ProviderScope.containerOf(
          context,
          listen: false,
        ).read(themeColorsProvider);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void update(FloorPlanExportSettings next) {
              setDialogState(() {
                settings = next;
              });
            }

            final service = FloorPlanExportService(
              document: widget.document,
              backgroundImage: widget.backgroundImage,
            );

            final exportBounds = service.resolveExportBounds(settings);
            final style = FloorPlanExportService.buildPainterStyle(settings);

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1080,
                  maxHeight: 820,
                ),
                child: Material(
                  elevation: 24,
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      children: [
                        _ExportDialogHeader(
                          title: 'export_plan_title'.tr,
                          subtitle: 'export_plan_subtitle'.tr,
                          onClose: () => Navigator.of(context).pop(null),
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    18,
                                    9,
                                    18,
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: _ExportPreviewCard(
                                          document: widget.document,
                                          backgroundImage:
                                              settings.showBackgroundImage
                                                  ? widget.backgroundImage
                                                  : null,
                                          exportBounds: exportBounds,
                                          settings: settings,
                                          style: style,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _ExportSummaryStrip(
                                        settings: settings,
                                        exportBounds: exportBounds,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                color: theme.dashboardBoarder,
                              ),
                              Expanded(
                                flex: 5,
                                child: _ExportSettingsPanel(
                                  settings: settings,
                                  onChanged: update,
                                  onApplyPreset: (mode) {
                                    update(
                                      FloorPlanExportService.applyThemePreset(
                                        settings.copyWith(themeMode: mode),
                                        mode,
                                        theme,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        _ExportDialogFooter(
                          settings: settings,
                          onCancel: () => Navigator.of(context).pop(null),
                          onExport: () => Navigator.of(context).pop(settings),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ExportDialogHeader extends ConsumerWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _ExportDialogHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: theme.textColor.withAlpha(8),
        border: Border(
          bottom: BorderSide(color: theme.dashboardBoarder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(32),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.themeColor.withAlpha(80),
              ),
            ),
            child: Icon(
              Icons.ios_share_outlined,
              color: theme.themeColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(150),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close,
              color: theme.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportDialogFooter extends ConsumerWidget {
  final FloorPlanExportSettings settings;
  final VoidCallback onCancel;
  final VoidCallback onExport;

  const _ExportDialogFooter({
    required this.settings,
    required this.onCancel,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: theme.textColor.withAlpha(8),
        border: Border(
          top: BorderSide(color: theme.dashboardBoarder),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.textColor.withAlpha(140),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Format: ${settings.format.label} • ${settings.boundsMode.label} • ${settings.themeMode.label}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor.withAlpha(150),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: Text('cancel_button'.tr),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.download_done_outlined),
            label: Text('export_button'.tr),
          ),
        ],
      ),
    );
  }
}

class _ExportSettingsPanel extends ConsumerWidget {
  final FloorPlanExportSettings settings;
  final ValueChanged<FloorPlanExportSettings> onChanged;
  final ValueChanged<FloorPlanExportThemeMode> onApplyPreset;

  const _ExportSettingsPanel({
    required this.settings,
    required this.onChanged,
    required this.onApplyPreset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      color: theme.dashboardContainer,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExportSectionCard(
              title: 'basic_settings_title'.tr,
              icon: Icons.tune,
              children: [
                _ExportDropdown<FloorPlanExportFormat>(
                  label: 'file_format_label'.tr,
                  value: settings.format,
                  values: FloorPlanExportFormat.values
                      .where((item) => item != FloorPlanExportFormat.webp)
                      .toList(),
                  labelBuilder: (item) => item.label,
                  onChanged: (value) {
                    if (value == null) return;

                    onChanged(
                      settings.copyWith(
                        format: value,
                        pixelRatio:
                            value == FloorPlanExportFormat.pdf ? 2.0 : 2.5,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ExportDropdown<FloorPlanExportBoundsMode>(
                  label: 'export_bounds_label'.tr,
                  value: settings.boundsMode,
                  values: FloorPlanExportBoundsMode.values,
                  labelBuilder: (item) => item.label,
                  onChanged: (value) {
                    if (value == null) return;
                    onChanged(settings.copyWith(boundsMode: value));
                  },
                ),
                const SizedBox(height: 12),
                _ExportDropdown<FloorPlanExportThemeMode>(
                  label: 'look_preset_label'.tr,
                  value: settings.themeMode,
                  values: FloorPlanExportThemeMode.values,
                  labelBuilder: (item) => item.label,
                  onChanged: (value) {
                    if (value == null) return;
                    onApplyPreset(value);
                  },
                ),
                const SizedBox(height: 12),
                _ExportNumberField(
                  label: 'margin_label'.tr,
                  suffix: 'px_unit'.tr,
                  value: settings.marginPx,
                  onChanged: (value) {
                    onChanged(
                      settings.copyWith(
                        marginPx: value.clamp(0, 1000).toDouble(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ExportNumberField(
                  label: 'render_scale_label'.tr,
                  suffix: 'times_unit'.tr,
                  value: settings.pixelRatio,
                  onChanged: (value) {
                    onChanged(
                      settings.copyWith(
                        pixelRatio: value.clamp(0.5, 5.0).toDouble(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ExportSectionCard(
              title: 'visibility_title'.tr,
              icon: Icons.layers_outlined,
              children: [
                _ExportSwitch(
                  title: 'background_image_label'.tr,
                  value: settings.showBackgroundImage,
                  onChanged: (value) {
                    onChanged(settings.copyWith(showBackgroundImage: value));
                  },
                ),
                _ExportSwitch(
                  title: 'grid_label'.tr,
                  value: settings.showGrid,
                  onChanged: (value) {
                    onChanged(settings.copyWith(showGrid: value));
                  },
                ),
                _ExportSwitch(
                  title: 'grid_label'.tr,
                  value: settings.showWallDimensions,
                  onChanged: (value) {
                    onChanged(settings.copyWith(showWallDimensions: value));
                  },
                ),
                _ExportSwitch(
                  title: 'corner_angles_label'.tr,
                  value: settings.showCornerAngles,
                  onChanged: (value) {
                    onChanged(settings.copyWith(showCornerAngles: value));
                  },
                ),
                _ExportSwitch(
                  title: 'room_names_label'.tr,
                  value: settings.showRoomLabels,
                  onChanged: (value) {
                    onChanged(settings.copyWith(showRoomLabels: value));
                  },
                ),
                _ExportSwitch(
                  title: 'room_areas_label'.tr,
                  value: settings.showRoomAreas,
                  onChanged: (value) {
                    onChanged(settings.copyWith(showRoomAreas: value));
                  },
                ),
                _ExportSwitch(
                  title:'room_fill_label'.tr,
                  value: settings.showRoomFill,
                  onChanged: (value) {
                    onChanged(settings.copyWith(showRoomFill: value));
                  },
                ),
                _ExportSwitch(
                  title: 'room_highlight_label'.tr,
                  value: settings.highlightRooms,
                  onChanged: (value) {
                    onChanged(settings.copyWith(highlightRooms: value));
                  },
                ),
                _ExportSwitch(
                  title: 'assets_label'.tr,
                  value: settings.showAssets,
                  onChanged: (value) {
                    onChanged(settings.copyWith(showAssets: value));
                  },
                ),
                _ExportSwitch(
                  title: 'openings_label'.tr,
                  value: settings.showOpenings,
                  onChanged: (value) {
                    onChanged(settings.copyWith(showOpenings: value));
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ExportSectionCard(
              title: 'colors_title'.tr,
              icon: Icons.palette_outlined,
              children: [
                _ExportColorField(
                  label: 'background_color_label'.tr,
                  value: settings.backgroundColorHex,
                  onChanged: (value) {
                    onChanged(settings.copyWith(backgroundColorHex: value));
                  },
                ),
                const SizedBox(height: 10),
                _ExportColorField(
                  label: 'grid_label'.tr,
                  value: settings.gridColorHex,
                  onChanged: (value) {
                    onChanged(settings.copyWith(gridColorHex: value));
                  },
                ),
                const SizedBox(height: 10),
                _ExportColorField(
                  label: 'walls_color_label'.tr,
                  value: settings.wallColorHex,
                  onChanged: (value) {
                    onChanged(settings.copyWith(wallColorHex: value));
                  },
                ),
                const SizedBox(height: 10),
                _ExportColorField(
                  label: 'virtual_walls_color_label'.tr,
                  value: settings.virtualWallColorHex,
                  onChanged: (value) {
                    onChanged(settings.copyWith(virtualWallColorHex: value));
                  },
                ),
                const SizedBox(height: 10),
                _ExportColorField(
                  label: 'openings_color_label'.tr,
                  value: settings.openingColorHex,
                  onChanged: (value) {
                    onChanged(settings.copyWith(openingColorHex: value));
                  },
                ),
                const SizedBox(height: 10),
                _ExportColorField(
                  label: 'assets_fill_color_label'.tr,
                  value: settings.assetFillColorHex,
                  onChanged: (value) {
                    onChanged(settings.copyWith(assetFillColorHex: value));
                  },
                ),
                const SizedBox(height: 10),
                _ExportColorField(
                  label: 'assets_stroke_color_label'.tr,
                  value: settings.assetStrokeColorHex,
                  onChanged: (value) {
                    onChanged(settings.copyWith(assetStrokeColorHex: value));
                  },
                ),
                const SizedBox(height: 10),
                _ExportColorField(
                  label: 'rooms_color_label'.tr,
                  value: settings.roomFillColorHex,
                  onChanged: (value) {
                    onChanged(settings.copyWith(roomFillColorHex: value));
                  },
                ),
                const SizedBox(height: 10),
                _ExportColorField(
                  label:'rooms_highlight_color_label'.tr,
                  value: settings.roomHighlightColorHex,
                  onChanged: (value) {
                    onChanged(
                      settings.copyWith(roomHighlightColorHex: value),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _ExportColorField(
                  label: 'labels_color_label'.tr,
                  value: settings.labelColorHex,
                  onChanged: (value) {
                    onChanged(settings.copyWith(labelColorHex: value));
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ExportSectionCard(
              title:'opacity_title'.tr,
              icon: Icons.opacity,
              children: [
                _ExportNumberField(
                  label: 'room_fill_opacity_label'.tr,
                  suffix: '0-1',
                  value: settings.roomFillOpacity,
                  onChanged: (value) {
                    onChanged(
                      settings.copyWith(
                        roomFillOpacity: value.clamp(0.0, 1.0).toDouble(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ExportNumberField(
                  label: 'room_highlight_opacity_label'.tr,
                  suffix: '0-1',
                  value: settings.roomHighlightOpacity,
                  onChanged: (value) {
                    onChanged(
                      settings.copyWith(
                        roomHighlightOpacity:
                            value.clamp(0.0, 1.0).toDouble(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportSectionCard extends ConsumerWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ExportSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.textColor.withAlpha(8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dashboardBoarder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: theme.themeColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ExportSummaryStrip extends ConsumerWidget {
  final FloorPlanExportSettings settings;
  final Rect exportBounds;

  const _ExportSummaryStrip({
    required this.settings,
    required this.exportBounds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.textColor.withAlpha(8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dashboardBoarder,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ExportInfoChip(
            label: 'format_label'.tr,
            value: settings.format.label,
          ),
          _ExportInfoChip(
            label: 'bounds_label'.tr,
            value: settings.boundsMode.label,
          ),
          _ExportInfoChip(
            label: 'style_label'.tr,
            value: settings.themeMode.label,
          ),
          _ExportInfoChip(
            label: 'size_label'.tr,
            value:
                '${exportBounds.width.toStringAsFixed(0)} × ${exportBounds.height.toStringAsFixed(0)}',
          ),
          _ExportInfoChip(
            label: 'scale_label'.tr,
            value: '${settings.pixelRatio.toStringAsFixed(1)}x',
          ),
        ],
      ),
    );
  }
}

class _ExportInfoChip extends ConsumerWidget {
  final String label;
  final String value;

  const _ExportInfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.dashboardBoarder,
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: theme.textColor,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StyledFloorPlanExportPainter extends CustomPainter {
  final FloorPlanDocument document;
  final FloorPlanPainterStyle style;
  final bool showCornerAngles;
  final bool showRoomLabels;
  final bool showRoomAreas;

  const _StyledFloorPlanExportPainter({
    required this.document,
    required this.style,
    required this.showCornerAngles,
    required this.showRoomLabels,
    required this.showRoomAreas,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawRooms(canvas);
    _drawWalls(canvas);
    _drawOpenings(canvas);
    _drawAssets(canvas);
    _drawCornerAngles(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    if (!style.showGrid) return;

    final gridSize = document.canvas.gridSize <= 0
        ? 20.0
        : document.canvas.gridSize.toDouble();

    final minorPaint = Paint()
      ..color = style.gridColor.withOpacity(0.32)
      ..strokeWidth = 1;

    final majorPaint = Paint()
      ..color = style.gridColor.withOpacity(0.58)
      ..strokeWidth = 1.4;

    for (double x = 0; x <= document.canvas.width; x += gridSize) {
      final index = (x / gridSize).round();
      final paint = index % 5 == 0 ? majorPaint : minorPaint;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, document.canvas.height),
        paint,
      );
    }

    for (double y = 0; y <= document.canvas.height; y += gridSize) {
      final index = (y / gridSize).round();
      final paint = index % 5 == 0 ? majorPaint : minorPaint;

      canvas.drawLine(
        Offset(0, y),
        Offset(document.canvas.width, y),
        paint,
      );
    }
  }

  void _drawRooms(Canvas canvas) {
    for (final room in document.rooms) {
      final points = room.points.map((point) => point.toOffset()).toList();
      if (points.length < 3) continue;

      final path = Path()..moveTo(points.first.dx, points.first.dy);

      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      path.close();

      if (style.showRoomFill) {
        final fillPaint = Paint()
          ..color = style.roomFillColor.withOpacity(style.roomFillOpacity)
          ..style = PaintingStyle.fill;

        canvas.drawPath(path, fillPaint);
      }

      if (style.highlightRooms) {
        final highlightPaint = Paint()
          ..color =
              style.roomHighlightColor.withOpacity(style.roomHighlightOpacity)
          ..style = PaintingStyle.fill;

        canvas.drawPath(path, highlightPaint);
      }

      final borderPaint = Paint()
        ..color = style.roomHighlightColor.withOpacity(0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawPath(path, borderPaint);

      if (showRoomLabels || showRoomAreas) {
        _drawRoomLabel(canvas, room);
      }
    }
  }

  void _drawRoomLabel(Canvas canvas, FloorRoom room) {
    final area = room.areaM2(document.scale.pixelsPerMeter);

    final lines = <String>[
      if (showRoomLabels) room.name,
      if (showRoomAreas) _formatAreaLabel(area),
    ];

    if (lines.isEmpty) return;

    final text = lines.join('\n');
    final center = room.centroid();

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: style.labelColor,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromCenter(
      center: center,
      width: painter.width + 18,
      height: painter.height + 12,
    );

    final bgPaint = Paint()
      ..color = style.backgroundColor.withOpacity(0.72)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(8),
    );

    canvas.drawRRect(rrect, bgPaint);

    painter.paint(
      canvas,
      Offset(
        rect.left + 9,
        rect.top + 6,
      ),
    );
  }

  void _drawWalls(Canvas canvas) {
    for (final wall in document.walls) {
      final start = wall.start.toOffset();
      final end = wall.end.toOffset();

      final length = (end - start).distance;
      if (length <= 0.001) continue;

      final thicknessPx = _wallThicknessPxFromDocument(document, wall);
      final isVirtual = wall.isVirtual;

      final paint = Paint()
        ..color = isVirtual ? style.virtualWallColor : style.wallColor
        ..strokeWidth = isVirtual ? 2.2 : thicknessPx
        ..strokeCap = StrokeCap.square
        ..style = PaintingStyle.stroke;

      if (isVirtual) {
        _drawDashedLine(
          canvas: canvas,
          start: start,
          end: end,
          paint: paint,
          dash: 14,
          gap: 10,
        );
      } else {
        canvas.drawLine(start, end, paint);
      }

      if (style.showWallDimensions) {
        _drawWallLengthLabel(canvas, wall);
      }
    }
  }

  void _drawWallLengthLabel(Canvas canvas, FloorWall wall) {
    final start = wall.start.toOffset();
    final end = wall.end.toOffset();
    final vector = end - start;
    final lengthPx = vector.distance;

    if (lengthPx <= 0.001) return;

    final lengthM = wall.lengthM(document.scale.pixelsPerMeter);
    final text = '${lengthM.toStringAsFixed(2)} m';

    final normal = Offset(
      -vector.dy / lengthPx,
      vector.dx / lengthPx,
    );

    final center = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    final thickness = _wallThicknessPxFromDocument(document, wall);
    final labelCenter = center - normal * ((thickness / 2) + 20);

    _drawLabel(
      canvas: canvas,
      center: labelCenter,
      text: text,
      fontSize: 12,
      backgroundColor: style.backgroundColor.withOpacity(0.84),
      textColor: style.labelColor,
    );
  }

  void _drawOpenings(Canvas canvas) {
    if (!style.showOpenings) return;

    for (final door in document.doors) {
      _drawDoor(canvas, door);
    }

    for (final window in document.windows) {
      _drawWindow(canvas, window);
    }
  }

  void _drawDoor(Canvas canvas, Map<String, dynamic> door) {
    final wallId = door['wall_id']?.toString();
    if (wallId == null) return;

    final wall = _findWallById(wallId);
    if (wall == null) return;

    final start = wall.start.toOffset();
    final end = wall.end.toOffset();
    final vector = end - start;
    final length = vector.distance;

    if (length <= 0.001) return;

    final unit = Offset(vector.dx / length, vector.dy / length);
    final normal = Offset(-unit.dy, unit.dx);

    final position = (door['position'] as num?)?.toDouble() ?? 0.5;
    final widthM = (door['width_m'] as num?)?.toDouble() ?? 0.9;
    final type = door['type']?.toString() ?? 'single';

    final center = start + vector * position.clamp(0.0, 1.0);
    final halfWidth = widthM * document.scale.pixelsPerMeter / 2;

    final a = center - unit * halfWidth;
    final b = center + unit * halfWidth;

    final openingPaint = Paint()
      ..color = style.openingColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    canvas.drawLine(a, b, openingPaint);

    if (type == 'garage_door') {
      final garagePaint = Paint()
        ..color = style.openingColor.withOpacity(0.75)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      for (var i = -2; i <= 2; i++) {
        final offset = normal * (i * 8.0);
        canvas.drawLine(a + offset, b + offset, garagePaint);
      }

      return;
    }

    final swingPaint = Paint()
      ..color = style.openingColor.withOpacity(0.78)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final radius = math.max(24.0, halfWidth * 2);
    final hinge = a;
    final swingEnd = hinge + normal * radius;

    canvas.drawLine(hinge, swingEnd, swingPaint);

    final rect = Rect.fromCircle(
      center: hinge,
      radius: radius,
    );

    canvas.drawArc(
      rect,
      math.atan2(unit.dy, unit.dx),
      math.pi / 2,
      false,
      swingPaint,
    );
  }

  void _drawWindow(Canvas canvas, Map<String, dynamic> window) {
    final wallId = window['wall_id']?.toString();
    if (wallId == null) return;

    final wall = _findWallById(wallId);
    if (wall == null) return;

    final start = wall.start.toOffset();
    final end = wall.end.toOffset();
    final vector = end - start;
    final length = vector.distance;

    if (length <= 0.001) return;

    final unit = Offset(vector.dx / length, vector.dy / length);
    final normal = Offset(-unit.dy, unit.dx);

    final position = (window['position'] as num?)?.toDouble() ?? 0.5;
    final widthM = (window['width_m'] as num?)?.toDouble() ?? 1.2;

    final center = start + vector * position.clamp(0.0, 1.0);
    final halfWidth = widthM * document.scale.pixelsPerMeter / 2;

    final a = center - unit * halfWidth;
    final b = center + unit * halfWidth;

    final paint = Paint()
      ..color = style.openingColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    canvas.drawLine(a + normal * 4, b + normal * 4, paint);
    canvas.drawLine(a - normal * 4, b - normal * 4, paint);
  }

  void _drawAssets(Canvas canvas) {
    if (!style.showAssets) return;

    for (final asset in document.assets) {
      final widthPx = asset.widthM * document.scale.pixelsPerMeter;
      final depthPx = asset.depthM * document.scale.pixelsPerMeter;
      final center = asset.position.toOffset();

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: widthPx,
        height: depthPx,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(asset.rotationDeg * math.pi / 180.0);

      final fillPaint = Paint()
        ..color = style.assetFillColor.withOpacity(0.86)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = style.assetStrokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final rrect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(10),
      );

      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, strokePaint);

      final label = asset.label?.trim().isNotEmpty == true
          ? asset.label!.trim()
          : floorPlanAssetTypeFromKey(asset.type).label;

      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: style.labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: math.max(20, widthPx - 8));

      painter.paint(
        canvas,
        Offset(
          -painter.width / 2,
          -painter.height / 2,
        ),
      );

      canvas.restore();
    }
  }

  void _drawCornerAngles(Canvas canvas) {
    if (!showCornerAngles) return;

    final labels = _buildCornerAngleLabels(document);

    for (final label in labels) {
      _drawLabel(
        canvas: canvas,
        center: label.labelPosition,
        text: _formatAngleLabel(label.angleDeg),
        fontSize: 11,
        backgroundColor: style.roomHighlightColor.withOpacity(0.72),
        textColor: style.labelColor,
      );
    }
  }

  void _drawLabel({
    required Canvas canvas,
    required Offset center,
    required String text,
    required double fontSize,
    required Color backgroundColor,
    required Color textColor,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromCenter(
      center: center,
      width: painter.width + 12,
      height: painter.height + 8,
    );

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(7),
    );

    canvas.drawRRect(rrect, bgPaint);

    painter.paint(
      canvas,
      Offset(
        rect.left + 6,
        rect.top + 4,
      ),
    );
  }

  void _drawDashedLine({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required Paint paint,
    required double dash,
    required double gap,
  }) {
    _floorPlanDrawDashedLine(
      canvas: canvas,
      start: start,
      end: end,
      paint: paint,
      dash: dash,
      gap: gap,
    );
  }

  FloorWall? _findWallById(String id) {
    for (final wall in document.walls) {
      if (wall.id == id) return wall;
    }

    return null;
  }

  @override
  bool shouldRepaint(covariant _StyledFloorPlanExportPainter oldDelegate) {
    return oldDelegate.document != document ||
        oldDelegate.style != style ||
        oldDelegate.showCornerAngles != showCornerAngles ||
        oldDelegate.showRoomLabels != showRoomLabels ||
        oldDelegate.showRoomAreas != showRoomAreas;
  }
}

class _ExportPreviewCard extends ConsumerWidget {
  final FloorPlanDocument document;
  final FloorPlanBackgroundImage? backgroundImage;
  final Rect exportBounds;
  final FloorPlanExportSettings settings;
  final FloorPlanPainterStyle style;

  const _ExportPreviewCard({
    required this.document,
    required this.backgroundImage,
    required this.exportBounds,
    required this.settings,
    required this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final safeWidth = exportBounds.width <= 1 ? 1.0 : exportBounds.width;
    final safeHeight = exportBounds.height <= 1 ? 1.0 : exportBounds.height;

    final aspectRatio = safeWidth / safeHeight;
    final previewHeight = aspectRatio > 2.2 ? 220.0 : 360.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.textColor.withAlpha(10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.dashboardBoarder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: theme.textColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'export_preview_title'.tr,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${safeWidth.toStringAsFixed(0)} × ${safeHeight.toStringAsFixed(0)} px',
                style: TextStyle(
                  color: theme.textColor.withAlpha(150),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                color: style.backgroundColor,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final previewSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );

                    final scale = math.min(
                      previewSize.width / safeWidth,
                      previewSize.height / safeHeight,
                    );

                    final paintedWidth = safeWidth * scale;
                    final paintedHeight = safeHeight * scale;

                    final dx = (previewSize.width - paintedWidth) / 2 -
                        exportBounds.left * scale;

                    final dy = (previewSize.height - paintedHeight) / 2 -
                        exportBounds.top * scale;

                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(
                          child: Container(
                            color: style.backgroundColor,
                          ),
                        ),
                        Transform(
                          transform: Matrix4.identity()
                            ..translate(dx, dy)
                            ..scale(scale),
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: document.canvas.width,
                            height: document.canvas.height,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                if (backgroundImage != null)
                                  _FloorPlanBackgroundLayer(
                                    backgroundImage: backgroundImage,
                                  ),
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _StyledFloorPlanExportPainter(
                                      document: document,
                                      style: style,
                                      showCornerAngles:
                                          settings.showCornerAngles,
                                      showRoomLabels: settings.showRoomLabels,
                                      showRoomAreas: settings.showRoomAreas,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            settings.boundsMode == FloorPlanExportBoundsMode.content
                ? '${'export_cropped_to_plan_with_margin'.tr} ${settings.marginPx.toStringAsFixed(0)} px.'
                : 'export_will_cover_full_canvas'.tr,
            style: TextStyle(
              color: theme.textColor.withAlpha(150),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;

  const _ExportDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final theme = ref.watch(themeColorsProvider);

        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: theme.textColor),
            floatingLabelStyle: TextStyle(
              color: theme.textColor.withAlpha(150),
            ),
            filled: true,
            fillColor: theme.adPopBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.dashboardBoarder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.dashboardBoarder,
              ),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: theme.adPopBackground,
              iconEnabledColor: theme.textColor,
              items: values.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}

class _ExportNumberField extends StatefulWidget {
  final String label;
  final String suffix;
  final double value;
  final ValueChanged<double> onChanged;

  const _ExportNumberField({
    required this.label,
    required this.suffix,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ExportNumberField> createState() => _ExportNumberFieldState();
}

class _ExportNumberFieldState extends State<_ExportNumberField> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(
      text: _formatInitialValue(widget.value),
    );
  }

  @override
  void didUpdateWidget(covariant _ExportNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      final nextText = _formatInitialValue(widget.value);

      if (controller.text != nextText) {
        controller.text = nextText;
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String _formatInitialValue(double value) {
    final rounded = value.roundToDouble();

    if ((value - rounded).abs() < 0.001) {
      return rounded.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  void _submit() {
    final parsed = _parseDouble(controller.text);
    if (parsed == null) return;

    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return CoreTextField(
      label: widget.label,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Center(
          widthFactor: 1,
          child: Text(widget.suffix),
        ),
      ),
      onSubmitted: (_) => _submit(),
      onChanged: (_) => _submit(),
    );
  }
}

class _ExportSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ExportSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final theme = ref.watch(themeColorsProvider);

        return SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: value,
          onChanged: onChanged,
          title: Text(
            title,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }
}

class _ExportColorField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _ExportColorField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ColorPickerField(
      label: label,
      value: value,
      onChanged: onChanged,
    );
  }
}

