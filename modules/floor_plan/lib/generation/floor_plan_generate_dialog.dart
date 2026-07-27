import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:floor_plan/generation/floor_plan_front_generator_service.dart';
import 'package:floor_plan/generation/floor_plan_generation_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:core/theme/apptheme.dart';

class FloorPlanGenerateDialog extends ConsumerStatefulWidget {
  const FloorPlanGenerateDialog({
    super.key,
  });

  static Future<FloorPlanGenerationApplyResult?> show(BuildContext context) {
    return showDialog<FloorPlanGenerationApplyResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FloorPlanGenerateDialog(),
    );
  }

  @override
  ConsumerState<FloorPlanGenerateDialog> createState() =>
      _FloorPlanGenerateDialogState();
}

class _FloorPlanGenerateDialogState
    extends ConsumerState<FloorPlanGenerateDialog> {
  final _lengthController = TextEditingController(text: '4.00');
  final _generator = const FloorPlanFrontGeneratorService();

  Timer? _autoDetectionDebounce;

  Uint8List? _imageBytes;
  ui.Image? _image;

  Offset? _calibrationStart;
  Offset? _calibrationEnd;

  FloorPlanDetectedLine? _autoCalibrationLine;

  bool _isPicking = false;
  bool _isGenerating = false;
  bool _isAutoCalibrating = false;

  bool _replaceExistingWalls = false;
  bool _useImageAsBackground = true;

  bool _autoCalibrationEnabled = true;
  bool _autoDetectionEnabled = true;
  bool _detectObjects = true;
  bool _showMeasurements = true;

  FloorPlanWallMaskMode _wallMaskMode = FloorPlanWallMaskMode.darkAndColor;

  int _darkThreshold = 135;
  int _minLineLengthPx = 64;
  int _mergeDistancePx = 12;
  double _snapDistancePx = 16;

  String? _error;
  String? _autoCalibrationMessage;

  List<FloorPlanDetectedLine> _detectedLines = const [];
  List<FloorPlanDetectedObject> _detectedObjects = const [];
  FloorPlanGenerationMetrics? _metrics;

  double? get _calibrationPxLength {
    final a = _calibrationStart;
    final b = _calibrationEnd;

    if (a == null || b == null) return null;
    return (b - a).distance;
  }

  double? get _realLengthM {
    final value = _lengthController.text.replaceAll(',', '.').trim();
    final parsed = double.tryParse(value);

    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  double? get _pixelsPerMeter {
    final px = _calibrationPxLength;
    final meters = _realLengthM;

    if (px == null || meters == null) return null;
    if (px <= 0 || meters <= 0) return null;

    return px / meters;
  }

  @override
  void initState() {
    super.initState();
    _lengthController.addListener(_scheduleAutoGenerate);
  }

  @override
  void dispose() {
    _autoDetectionDebounce?.cancel();
    _lengthController.removeListener(_scheduleAutoGenerate);
    _lengthController.dispose();
    super.dispose();
  }

  void _clearDetection() {
    _detectedLines = const [];
    _detectedObjects = const [];
    _metrics = null;
  }

  FloorPlanDetectionSettings _currentDetectionSettings({
    bool forCalibration = false,
  }) {
    final minLineLength = forCalibration
        ? (_minLineLengthPx < 44 ? 44 : _minLineLengthPx)
        : _minLineLengthPx;

    return FloorPlanDetectionSettings(
      wallMaskMode: _wallMaskMode,
      darkThreshold: _darkThreshold,
      minLineLengthPx: minLineLength,
      mergeDistancePx: _mergeDistancePx,
      snapDistancePx: _snapDistancePx,
      intersectionSnapDistancePx: _snapDistancePx + 6,
      detectObjects: forCalibration ? false : _detectObjects,
    );
  }

  Future<void> _pickImage() async {
    if (_isPicking) return;

    setState(() {
      _isPicking = true;
      _error = null;
      _autoCalibrationMessage = null;
      _autoCalibrationLine = null;
      _clearDetection();
      _calibrationStart = null;
      _calibrationEnd = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        withData: true,
        allowedExtensions: const [
          'png',
          'jpg',
          'jpeg',
          'webp',
        ],
      );

      final file = result?.files.single;
      final bytes = file?.bytes;

      if (bytes == null || bytes.isEmpty) {
        return;
      }

      final decoded = await decodeFloorPlanImage(bytes);

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _image = decoded;
      });

      if (_autoCalibrationEnabled) {
        await _runAutoCalibration(silent: true);
      }

      _scheduleAutoGenerate();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  void _handleImageTap(TapDownDetails details) {
    final image = _image;
    if (image == null) return;

    final point = details.localPosition;

    final clamped = Offset(
      point.dx.clamp(0.0, image.width.toDouble()).toDouble(),
      point.dy.clamp(0.0, image.height.toDouble()).toDouble(),
    );

    setState(() {
      _autoCalibrationEnabled = false;
      _autoCalibrationLine = null;
      _autoCalibrationMessage = 'manual_calibration_message'.tr;

      if (_calibrationStart == null ||
          (_calibrationStart != null && _calibrationEnd != null)) {
        _calibrationStart = clamped;
        _calibrationEnd = null;
        _clearDetection();
      } else {
        _calibrationEnd = clamped;
        _clearDetection();
      }
    });

    _scheduleAutoGenerate();
  }

  void _scheduleAutoGenerate() {
    if (!_autoDetectionEnabled) return;

    _autoDetectionDebounce?.cancel();
    _autoDetectionDebounce = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      _tryAutoGenerate();
    });
  }

  Future<void> _tryAutoGenerate() async {
    if (!_autoDetectionEnabled) return;
    if (_isPicking || _isGenerating || _isAutoCalibrating) return;
    if (_image == null || _imageBytes == null) return;
    if (_pixelsPerMeter == null) return;

    await _generate(silent: true);
  }

  Future<void> _runAutoFlow() async {
    await _runAutoCalibration(silent: false);
    await _generate(silent: false);
  }

  Future<void> _runAutoCalibration({
    required bool silent,
  }) async {
    final image = _image;

    if (image == null) {
      if (!silent) {
        setState(() {
          _error = 'please_upload_image_first'.tr;
        });
      }
      return;
    }

    if (_isAutoCalibrating || _isGenerating) return;

    setState(() {
      _isAutoCalibrating = true;
      _error = null;
      _autoCalibrationMessage = 'searching_for_calibration_segment'.tr;
      _autoCalibrationLine = null;
      _clearDetection();
    });

    try {
      final result = await _generator.analyzeFloorPlanImage(
        image: image,
        pixelsPerMeter: 100,
        settings: _currentDetectionSettings(forCalibration: true),
      );

      final candidate = _pickBestCalibrationCandidate(
        lines: result.lines,
        image: image,
      );

      if (!mounted) return;

      setState(() {
        if (candidate == null) {
          _autoCalibrationMessage =
              'no_good_calibration_segment'.tr;
          _autoCalibrationLine = null;
          _calibrationStart = null;
          _calibrationEnd = null;
        } else {
          _autoCalibrationLine = candidate;
          _calibrationStart = candidate.start;
          _calibrationEnd = candidate.end;
          _autoCalibrationMessage =
              '${'found_calibration_segment_prefix'.tr} ${candidate.lengthPx.toStringAsFixed(0)} ${'found_calibration_segment_suffix'.tr}';
        }

        _clearDetection();
      });

      _scheduleAutoGenerate();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _autoCalibrationMessage = 'autocalibration_failed'.tr;
        if (!silent) {
          _error = e.toString();
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAutoCalibrating = false;
        });
      }
    }
  }

  FloorPlanDetectedLine? _pickBestCalibrationCandidate({
    required List<FloorPlanDetectedLine> lines,
    required ui.Image image,
  }) {
    final valid = lines.where((line) {
      if (!line.isValid) return false;
      if (line.lengthPx < _minLineLengthPx) return false;
      if (!line.isHorizontal && !line.isVertical) return false;
      return true;
    }).toList();

    if (valid.isEmpty) return null;

    double score(FloorPlanDetectedLine line) {
      var value = line.lengthPx;

      final nearImageBorder = _lineIsNearImageBorder(
        line: line,
        image: image,
        margin: 10,
      );

      if (nearImageBorder) {
        value *= 0.55;
      }

      final veryLongHorizontalBorder =
          line.isHorizontal && line.lengthPx > image.width * 0.86;

      final veryLongVerticalBorder =
          line.isVertical && line.lengthPx > image.height * 0.86;

      if (veryLongHorizontalBorder || veryLongVerticalBorder) {
        value *= 0.45;
      }

      return value;
    }

    valid.sort((a, b) => score(b).compareTo(score(a)));

    return valid.first;
  }

  bool _lineIsNearImageBorder({
    required FloorPlanDetectedLine line,
    required ui.Image image,
    required double margin,
  }) {
    final width = image.width.toDouble();
    final height = image.height.toDouble();

    final points = [line.start, line.end];

    var nearCount = 0;

    for (final point in points) {
      final near = point.dx <= margin ||
          point.dy <= margin ||
          point.dx >= width - margin ||
          point.dy >= height - margin;

      if (near) nearCount++;
    }

    return nearCount >= 2;
  }

  Future<void> _generate({
    bool silent = false,
  }) async {
    final image = _image;
    final bytes = _imageBytes;
    final ppm = _pixelsPerMeter;

    if (image == null || bytes == null) {
      if (!silent) {
        setState(() {
          _error = 'please_upload_image_first'.tr;
        });
      }
      return;
    }

    if (ppm == null) {
      if (!silent) {
        setState(() {
          _error =
              'set_scale_error_message'.tr;
        });
      }
      return;
    }

    if (_isGenerating || _isAutoCalibrating) return;

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final result = await _generator.analyzeFloorPlanImage(
        image: image,
        pixelsPerMeter: ppm,
        settings: _currentDetectionSettings(),
      );

      if (!mounted) return;

      setState(() {
        _detectedLines = result.lines;
        _detectedObjects = result.objects;
        _metrics = result.metrics;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        if (!silent) {
          _error = e.toString();
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _apply() {
    final image = _image;
    final bytes = _imageBytes;
    final ppm = _pixelsPerMeter;

    if (image == null || bytes == null || ppm == null) {
      setState(() {
        _error =
            'missing_image_or_scale_error'.tr;
      });
      return;
    }

    final draft = FloorPlanGeneratedDraft(
      imageBytes: bytes,
      imageWidth: image.width,
      imageHeight: image.height,
      pixelsPerMeter: ppm,
      lines: _detectedLines,
      objects: _detectedObjects,
      metrics: _metrics,
    );

    Navigator.of(context).pop(
      FloorPlanGenerationApplyResult(
        draft: draft,
        replaceExistingWalls: _replaceExistingWalls,
        useImageAsBackground: _useImageAsBackground,
      ),
    );
  }

  void _onDetectionSettingChanged(VoidCallback update) {
    setState(() {
      update();
      _clearDetection();
    });

    if (_autoCalibrationEnabled && _image != null) {
      _autoDetectionDebounce?.cancel();
      _autoDetectionDebounce = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _runAutoCalibration(silent: true);
      });
    } else {
      _scheduleAutoGenerate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);
    final image = _image;

    return Dialog(
      backgroundColor: theme.dashboardContainer,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1180,
          maxHeight: 860,
        ),
        child: Column(
          children: [
            _Header(
              title: 'generate_plan_from_image_title'.tr,
              subtitle:
                  'generate_plan_subtitle'.tr,
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 920;

                  if (isNarrow) {
                    return Column(
                      children: [
                        Expanded(
                          child: _PreviewContainer(
                            theme: theme,
                            image: image,
                            isPicking: _isPicking,
                            calibrationStart: _calibrationStart,
                            calibrationEnd: _calibrationEnd,
                            autoCalibrationLine: _autoCalibrationLine,
                            detectedLines: _detectedLines,
                            detectedObjects: _detectedObjects,
                            pixelsPerMeter: _pixelsPerMeter,
                            showMeasurements: _showMeasurements,
                            onPick: _pickImage,
                            onTapDown: _handleImageTap,
                          ),
                        ),
                        SizedBox(
                          height: 390,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _buildSidePanel(image != null),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _PreviewContainer(
                          theme: theme,
                          image: image,
                          isPicking: _isPicking,
                          calibrationStart: _calibrationStart,
                          calibrationEnd: _calibrationEnd,
                          autoCalibrationLine: _autoCalibrationLine,
                          detectedLines: _detectedLines,
                          detectedObjects: _detectedObjects,
                          pixelsPerMeter: _pixelsPerMeter,
                          showMeasurements: _showMeasurements,
                          onPick: _pickImage,
                          onTapDown: _handleImageTap,
                        ),
                      ),
                      SizedBox(
                        width: 386,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                          child: _buildSidePanel(image != null),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanel(bool hasImage) {
    return _SidePanel(
      isPicking: _isPicking,
      isGenerating: _isGenerating,
      isAutoCalibrating: _isAutoCalibrating,
      hasImage: hasImage,
      calibrationPxLength: _calibrationPxLength,
      pixelsPerMeter: _pixelsPerMeter,
      detectedLinesCount: _detectedLines.length,
      detectedObjectsCount: _detectedObjects.length,
      metrics: _metrics,
      lengthController: _lengthController,
      replaceExistingWalls: _replaceExistingWalls,
      useImageAsBackground: _useImageAsBackground,
      autoCalibrationEnabled: _autoCalibrationEnabled,
      autoDetectionEnabled: _autoDetectionEnabled,
      autoCalibrationMessage: _autoCalibrationMessage,
      detectObjects: _detectObjects,
      showMeasurements: _showMeasurements,
      wallMaskMode: _wallMaskMode,
      darkThreshold: _darkThreshold,
      minLineLengthPx: _minLineLengthPx,
      mergeDistancePx: _mergeDistancePx,
      snapDistancePx: _snapDistancePx,
      error: _error,
      onPick: _pickImage,
      onAutoCalibration: () => _runAutoCalibration(silent: false),
      onAutoFlow: _runAutoFlow,
      onGenerate: () => _generate(silent: false),
      onApply: _apply,
      onReplaceExistingWallsChanged: (value) {
        setState(() {
          _replaceExistingWalls = value;
        });
      },
      onUseImageAsBackgroundChanged: (value) {
        setState(() {
          _useImageAsBackground = value;
        });
      },
      onAutoCalibrationEnabledChanged: (value) {
        setState(() {
          _autoCalibrationEnabled = value;
          if (!value) {
            _autoCalibrationMessage = 'autocalibration_disabled_message'.tr;
          }
        });

        if (value && _image != null) {
          _runAutoCalibration(silent: true);
        }
      },
      onAutoDetectionEnabledChanged: (value) {
        setState(() {
          _autoDetectionEnabled = value;
        });

        if (value) {
          _scheduleAutoGenerate();
        }
      },
      onDetectObjectsChanged: (value) {
        _onDetectionSettingChanged(() {
          _detectObjects = value;
        });
      },
      onShowMeasurementsChanged: (value) {
        setState(() {
          _showMeasurements = value;
        });
      },
      onWallMaskModeChanged: (value) {
        _onDetectionSettingChanged(() {
          _wallMaskMode = value;
        });
      },
      onDarkThresholdChanged: (value) {
        _onDetectionSettingChanged(() {
          _darkThreshold = value;
        });
      },
      onMinLineLengthChanged: (value) {
        _onDetectionSettingChanged(() {
          _minLineLengthPx = value;
        });
      },
      onMergeDistanceChanged: (value) {
        _onDetectionSettingChanged(() {
          _mergeDistancePx = value;
        });
      },
      onSnapDistanceChanged: (value) {
        _onDetectionSettingChanged(() {
          _snapDistancePx = value;
        });
      },
    );
  }
}

class _PreviewContainer extends StatelessWidget {
  final dynamic theme;
  final ui.Image? image;
  final bool isPicking;
  final Offset? calibrationStart;
  final Offset? calibrationEnd;
  final FloorPlanDetectedLine? autoCalibrationLine;
  final List<FloorPlanDetectedLine> detectedLines;
  final List<FloorPlanDetectedObject> detectedObjects;
  final double? pixelsPerMeter;
  final bool showMeasurements;
  final VoidCallback onPick;
  final GestureTapDownCallback onTapDown;

  const _PreviewContainer({
    required this.theme,
    required this.image,
    required this.isPicking,
    required this.calibrationStart,
    required this.calibrationEnd,
    required this.autoCalibrationLine,
    required this.detectedLines,
    required this.detectedObjects,
    required this.pixelsPerMeter,
    required this.showMeasurements,
    required this.onPick,
    required this.onTapDown,
  });

  @override
  Widget build(BuildContext context) {
    final currentImage = image;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 8, 16),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dashboardBoarder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: currentImage == null
          ? _EmptyImageState(
              isPicking: isPicking,
              onPick: onPick,
            )
          : _ImageCalibrationPreview(
              image: currentImage,
              calibrationStart: calibrationStart,
              calibrationEnd: calibrationEnd,
              autoCalibrationLine: autoCalibrationLine,
              detectedLines: detectedLines,
              detectedObjects: detectedObjects,
              pixelsPerMeter: pixelsPerMeter,
              showMeasurements: showMeasurements,
              onTapDown: onTapDown,
            ),
    );
  }
}

class _Header extends ConsumerWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dashboardBoarder,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.themeColor.withAlpha(38),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: theme.themeColor,
            ),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(145),
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

class _EmptyImageState extends ConsumerWidget {
  final bool isPicking;
  final VoidCallback onPick;

  const _EmptyImageState({
    required this.isPicking,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upload_file_outlined,
              size: 54,
              color: theme.textColor.withAlpha(150),
            ),
            const SizedBox(height: 16),
            Text(
              'upload_plan_image_title'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'upload_plan_image_subtitle'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor.withAlpha(160),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: isPicking ? null : onPick,
              icon: isPicking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined),
              label: Text(isPicking ? 'selecting_status'.tr : 'change_image_button'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageCalibrationPreview extends ConsumerWidget {
  final ui.Image image;
  final Offset? calibrationStart;
  final Offset? calibrationEnd;
  final FloorPlanDetectedLine? autoCalibrationLine;
  final List<FloorPlanDetectedLine> detectedLines;
  final List<FloorPlanDetectedObject> detectedObjects;
  final double? pixelsPerMeter;
  final bool showMeasurements;
  final GestureTapDownCallback onTapDown;

  const _ImageCalibrationPreview({
    required this.image,
    required this.calibrationStart,
    required this.calibrationEnd,
    required this.autoCalibrationLine,
    required this.detectedLines,
    required this.detectedObjects,
    required this.pixelsPerMeter,
    required this.showMeasurements,
    required this.onTapDown,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InteractiveViewer(
      minScale: 0.1,
      maxScale: 8,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onTapDown,
          child: SizedBox(
            width: image.width.toDouble(),
            height: image.height.toDouble(),
            child: CustomPaint(
              foregroundPainter: _GenerationPreviewPainter(
                calibrationStart: calibrationStart,
                calibrationEnd: calibrationEnd,
                autoCalibrationLine: autoCalibrationLine,
                detectedLines: detectedLines,
                detectedObjects: detectedObjects,
                pixelsPerMeter: pixelsPerMeter,
                showMeasurements: showMeasurements,
              ),
              child: RawImage(
                image: image,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenerationPreviewPainter extends CustomPainter {
  final Offset? calibrationStart;
  final Offset? calibrationEnd;
  final FloorPlanDetectedLine? autoCalibrationLine;
  final List<FloorPlanDetectedLine> detectedLines;
  final List<FloorPlanDetectedObject> detectedObjects;
  final double? pixelsPerMeter;
  final bool showMeasurements;

  const _GenerationPreviewPainter({
    required this.calibrationStart,
    required this.calibrationEnd,
    required this.autoCalibrationLine,
    required this.detectedLines,
    required this.detectedObjects,
    required this.pixelsPerMeter,
    required this.showMeasurements,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final autoLine = autoCalibrationLine;

    if (autoLine != null) {
      final autoPaint = Paint()
        ..color = Colors.green.withAlpha(230)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(autoLine.start, autoLine.end, autoPaint);
      canvas.drawCircle(
        autoLine.start,
        7,
        Paint()..color = Colors.greenAccent,
      );
      canvas.drawCircle(
        autoLine.end,
        7,
        Paint()..color = Colors.greenAccent,
      );

      _paintLabel(
        canvas: canvas,
        text: 'AUTO',
        position: Offset(
          (autoLine.start.dx + autoLine.end.dx) / 2,
          (autoLine.start.dy + autoLine.end.dy) / 2,
        ) +
            const Offset(0, -28),
        color: Colors.green,
        fontSize: 14,
      );
    }

    final detectedPaint = Paint()
      ..color = Colors.blue.withAlpha(220)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final vertexPaint = Paint()
      ..color = Colors.cyanAccent.withAlpha(230)
      ..style = PaintingStyle.fill;

    final objectPaint = Paint()
      ..color = Colors.purple.withAlpha(55)
      ..style = PaintingStyle.fill;

    final objectBorderPaint = Paint()
      ..color = Colors.purple.withAlpha(230)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final line in detectedLines) {
      canvas.drawLine(line.start, line.end, detectedPaint);
      canvas.drawCircle(line.start, 4.5, vertexPaint);
      canvas.drawCircle(line.end, 4.5, vertexPaint);

      if (showMeasurements &&
          pixelsPerMeter != null &&
          pixelsPerMeter! > 0 &&
          detectedLines.length <= 140 &&
          line.lengthMeters(pixelsPerMeter!) >= 0.35) {
        final center = Offset(
          (line.start.dx + line.end.dx) / 2,
          (line.start.dy + line.end.dy) / 2,
        );

        final label =
            '${line.lengthMeters(pixelsPerMeter!).toStringAsFixed(2)} m';

        _paintLabel(
          canvas: canvas,
          text: label,
          position: center + const Offset(4, -18),
          color: Colors.blue,
        );
      }
    }

    for (final object in detectedObjects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(object.bounds, const Radius.circular(4)),
        objectPaint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(object.bounds, const Radius.circular(4)),
        objectBorderPaint,
      );

      if (detectedObjects.length <= 80) {
        _paintLabel(
          canvas: canvas,
          text: object.type.label,
          position: object.bounds.topLeft + const Offset(2, -16),
          color: Colors.purple,
        );
      }
    }

    final start = calibrationStart;
    final end = calibrationEnd;

    if (start != null) {
      canvas.drawCircle(
        start,
        8,
        Paint()..color = Colors.orange,
      );
    }

    if (end != null) {
      canvas.drawCircle(
        end,
        8,
        Paint()..color = Colors.orange,
      );
    }

    if (start != null && end != null) {
      final paint = Paint()
        ..color = Colors.orange
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, paint);

      final center = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2,
      );

      final label = '${(end - start).distance.toStringAsFixed(0)} px';

      _paintLabel(
        canvas: canvas,
        text: label,
        position: center - const Offset(0, 26),
        color: Colors.orange,
        fontSize: 18,
      );
    }
  }

  void _paintLabel({
    required Canvas canvas,
    required String text,
    required Offset position,
    required Color color,
    double fontSize = 13,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
          backgroundColor: Colors.white.withAlpha(220),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _GenerationPreviewPainter oldDelegate) {
    return oldDelegate.calibrationStart != calibrationStart ||
        oldDelegate.calibrationEnd != calibrationEnd ||
        oldDelegate.autoCalibrationLine != autoCalibrationLine ||
        oldDelegate.detectedLines != detectedLines ||
        oldDelegate.detectedObjects != detectedObjects ||
        oldDelegate.pixelsPerMeter != pixelsPerMeter ||
        oldDelegate.showMeasurements != showMeasurements;
  }
}

class _SidePanel extends ConsumerWidget {
  final bool isPicking;
  final bool isGenerating;
  final bool isAutoCalibrating;
  final bool hasImage;
  final double? calibrationPxLength;
  final double? pixelsPerMeter;
  final int detectedLinesCount;
  final int detectedObjectsCount;
  final FloorPlanGenerationMetrics? metrics;
  final TextEditingController lengthController;
  final bool replaceExistingWalls;
  final bool useImageAsBackground;
  final bool autoCalibrationEnabled;
  final bool autoDetectionEnabled;
  final String? autoCalibrationMessage;
  final bool detectObjects;
  final bool showMeasurements;
  final FloorPlanWallMaskMode wallMaskMode;
  final int darkThreshold;
  final int minLineLengthPx;
  final int mergeDistancePx;
  final double snapDistancePx;
  final String? error;

  final VoidCallback onPick;
  final VoidCallback onAutoCalibration;
  final VoidCallback onAutoFlow;
  final VoidCallback onGenerate;
  final VoidCallback onApply;

  final ValueChanged<bool> onReplaceExistingWallsChanged;
  final ValueChanged<bool> onUseImageAsBackgroundChanged;
  final ValueChanged<bool> onAutoCalibrationEnabledChanged;
  final ValueChanged<bool> onAutoDetectionEnabledChanged;
  final ValueChanged<bool> onDetectObjectsChanged;
  final ValueChanged<bool> onShowMeasurementsChanged;
  final ValueChanged<FloorPlanWallMaskMode> onWallMaskModeChanged;
  final ValueChanged<int> onDarkThresholdChanged;
  final ValueChanged<int> onMinLineLengthChanged;
  final ValueChanged<int> onMergeDistanceChanged;
  final ValueChanged<double> onSnapDistanceChanged;

  const _SidePanel({
    required this.isPicking,
    required this.isGenerating,
    required this.isAutoCalibrating,
    required this.hasImage,
    required this.calibrationPxLength,
    required this.pixelsPerMeter,
    required this.detectedLinesCount,
    required this.detectedObjectsCount,
    required this.metrics,
    required this.lengthController,
    required this.replaceExistingWalls,
    required this.useImageAsBackground,
    required this.autoCalibrationEnabled,
    required this.autoDetectionEnabled,
    required this.autoCalibrationMessage,
    required this.detectObjects,
    required this.showMeasurements,
    required this.wallMaskMode,
    required this.darkThreshold,
    required this.minLineLengthPx,
    required this.mergeDistancePx,
    required this.snapDistancePx,
    required this.error,
    required this.onPick,
    required this.onAutoCalibration,
    required this.onAutoFlow,
    required this.onGenerate,
    required this.onApply,
    required this.onReplaceExistingWallsChanged,
    required this.onUseImageAsBackgroundChanged,
    required this.onAutoCalibrationEnabledChanged,
    required this.onAutoDetectionEnabledChanged,
    required this.onDetectObjectsChanged,
    required this.onShowMeasurementsChanged,
    required this.onWallMaskModeChanged,
    required this.onDarkThresholdChanged,
    required this.onMinLineLengthChanged,
    required this.onMergeDistanceChanged,
    required this.onSnapDistanceChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isBusy = isPicking || isGenerating || isAutoCalibrating;

    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dashboardBoarder,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _StepCard(
            number: '1',
            title: 'step_1_title'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: isPicking ? null : onPick,
                  icon: isPicking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image_outlined),
                  label: Text(
                    isPicking
                        ? 'selecting_status'.tr
                        : hasImage
                            ? 'change_image_button'.tr
                            : 'select_image_button'.tr,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasImage
                      ? 'image_loaded_message'.tr
                      : 'supported_formats_message'.tr,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(145),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StepCard(
            number: '2',
            title: 'autocalibration_title'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  value: autoCalibrationEnabled,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: isBusy ? null : onAutoCalibrationEnabledChanged,
                  title: Text(
                    'autocalibration_label'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'autocalibration_description'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(135),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            hasImage && !isBusy ? onAutoCalibration : null,
                        icon: isAutoCalibrating
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.straighten),
                        label: Text(
                          isAutoCalibrating
                              ? 'searching_status'.tr
                              : 'find_calibration_segment_button'.tr,
                        ),
                      ),
                    ),
                  ],
                ),
                if (autoCalibrationMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    autoCalibrationMessage!,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(155),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: lengthController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'real_length_label'.tr,
                    suffixText: 'm',
                    filled: true,
                    fillColor: theme.dashboardContainer,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                _MetricRow(
                  label: 'calibration_segment_label'.tr,
                  value: calibrationPxLength == null
                      ? 'not_set_label'.tr
                      : '${calibrationPxLength!.toStringAsFixed(0)} px',
                ),
                _MetricRow(
                  label: 'scale_label'.tr,
                  value: pixelsPerMeter == null
                      ? 'missing_label'.tr
                      : '${pixelsPerMeter!.toStringAsFixed(2)} px/m',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StepCard(
            number: '3',
            title: 'autodetection_title'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  value: autoDetectionEnabled,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: onAutoDetectionEnabledChanged,
                  title: Text(
                    'autodetection_label'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'autodetection_description'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(135),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: hasImage && !isBusy ? onAutoFlow : null,
                  icon: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bolt),
                  label: Text('auto_calibration_detection_button'.tr),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StepCard(
            number: '4',
            title: 'detection_settings_title'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<FloorPlanWallMaskMode>(
                  value: wallMaskMode,
                  decoration: InputDecoration(
                    labelText: 'detection_mode_label'.tr,
                    filled: true,
                    fillColor: theme.dashboardContainer,
                    border: const OutlineInputBorder(),
                  ),
                  dropdownColor: theme.dashboardContainer,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                  items: FloorPlanWallMaskMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode.label),
                    );
                  }).toList(),
                  onChanged: isBusy
                      ? null
                      : (value) {
                          if (value != null) {
                            onWallMaskModeChanged(value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                _SliderSetting(
                  label: 'dark_lines_sensitivity_label'.tr,
                  valueLabel: '$darkThreshold',
                  value: darkThreshold.toDouble(),
                  min: 40,
                  max: 230,
                  divisions: 190,
                  onChanged: isBusy
                      ? null
                      : (value) => onDarkThresholdChanged(value.round()),
                ),
                _SliderSetting(
                  label: 'min_wall_length_label'.tr,
                  valueLabel: '$minLineLengthPx px',
                  value: minLineLengthPx.toDouble(),
                  min: 20,
                  max: 180,
                  divisions: 160,
                  onChanged: isBusy
                      ? null
                      : (value) => onMinLineLengthChanged(value.round()),
                ),
                _SliderSetting(
                  label: 'merge_fragments_label'.tr,
                  valueLabel: '$mergeDistancePx px',
                  value: mergeDistancePx.toDouble(),
                  min: 2,
                  max: 36,
                  divisions: 34,
                  onChanged: isBusy
                      ? null
                      : (value) => onMergeDistanceChanged(value.round()),
                ),
                _SliderSetting(
                  label: 'vertex_snap_label'.tr,
                  valueLabel: '${snapDistancePx.toStringAsFixed(0)} px',
                  value: snapDistancePx,
                  min: 4,
                  max: 40,
                  divisions: 36,
                  onChanged: isBusy ? null : onSnapDistanceChanged,
                ),
                SwitchListTile(
                  value: detectObjects,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: isBusy ? null : onDetectObjectsChanged,
                  title: Text(
                    'detect_objects_label'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'detect_objects_description'.tr,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(135),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
                SwitchListTile(
                  value: showMeasurements,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: onShowMeasurementsChanged,
                  title: Text(
                    'show_wall_lengths_label'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StepCard(
            number: '5',
            title: 'detection_metrics_title'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: hasImage && !isBusy ? onGenerate : null,
                  icon: isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    isGenerating ? 'detecting_status'.tr: 'detect_plan_now_button'.tr,
                  ),
                ),
                const SizedBox(height: 10),
                _MetricRow(
                  label: 'detected_walls_label'.tr,
                  value: '$detectedLinesCount',
                ),
                _MetricRow(
                  label: 'detected_objects_label'.tr,
                  value: '$detectedObjectsCount',
                ),
                if (metrics != null) ...[
                  const SizedBox(height: 6),
                  _MetricRow(
                    label: 'total_wall_length_label'.tr,
                    value:
                        '${metrics!.totalWallLengthM.toStringAsFixed(2)} m',
                  ),
                  _MetricRow(
                    label: 'longest_wall_label'.tr,
                    value:
                        '${metrics!.longestWallLengthM.toStringAsFixed(2)} m',
                  ),
                  _MetricRow(
                    label: 'estimated_footprint_label'.tr,
                    value:
                        '${metrics!.estimatedFootprintAreaM2.toStringAsFixed(2)} m²',
                  ),
                  _MetricRow(
                    label: 'confidence_label'.tr,
                    value:
                        '${(metrics!.averageConfidence * 100).toStringAsFixed(0)}%',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StepCard(
            number: '6',
            title: 'apply_title'.tr,
            child: Column(
              children: [
                SwitchListTile(
                  value: useImageAsBackground,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: onUseImageAsBackgroundChanged,
                  title: Text(
                    'use_image_as_background_label'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SwitchListTile(
                  value: replaceExistingWalls,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: onReplaceExistingWallsChanged,
                  title: Text(
                    'replace_existing_walls_label'.tr,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: hasImage ? onApply : null,
                    icon: const Icon(Icons.check),
                    label:Text('apply_to_canvas_button'.tr),
                  ),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withAlpha(100),
                ),
              ),
              child: Text(
                error!,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SliderSetting extends ConsumerWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double>? onChanged;

  const _SliderSetting({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(160),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                valueLabel,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _StepCard extends ConsumerWidget {
  final String number;
  final String title;
  final Widget child;

  const _StepCard({
    required this.number,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dashboardBoarder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: theme.themeColor.withAlpha(60),
                child: Text(
                  number,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MetricRow extends ConsumerWidget {
  final String label;
  final String value;

  const _MetricRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.textColor.withAlpha(150),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}