part of importer_field_mapper;

enum _CanvasDragPayloadType { sourceColumn, targetModel, targetField }

enum _CanvasModelLayoutMode { vertical, grid }

class _CanvasDragPayload {
  final _CanvasDragPayloadType type;
  final String id;
  final String? modelName;
  final String? fieldName;
  final String? columnName;

  const _CanvasDragPayload._({
    required this.type,
    required this.id,
    this.modelName,
    this.fieldName,
    this.columnName,
  });

  const _CanvasDragPayload.sourceColumn(String column)
    : this._(
        type: _CanvasDragPayloadType.sourceColumn,
        id: column,
        columnName: column,
      );

  const _CanvasDragPayload.targetModel(String modelName)
    : this._(
        type: _CanvasDragPayloadType.targetModel,
        id: modelName,
        modelName: modelName,
      );

  const _CanvasDragPayload.targetField({
    required String modelName,
    required String fieldName,
    String? columnName,
  }) : this._(
         type: _CanvasDragPayloadType.targetField,
         id: '$modelName.$fieldName',
         modelName: modelName,
         fieldName: fieldName,
         columnName: columnName,
       );

  bool get isSourceColumn => type == _CanvasDragPayloadType.sourceColumn;

  bool get isTargetModel => type == _CanvasDragPayloadType.targetModel;

  bool get isTargetField => type == _CanvasDragPayloadType.targetField;

  String? get effectiveColumnName {
    if (isSourceColumn) return columnName ?? id;
    if (isTargetField) return columnName;
    return null;
  }
}

class MapperCanvasView extends StatefulWidget {
  final String rootAnchorKey;
  final ThemeColors theme;
  final ImportOptions options;
  final ImportFormState formState;
  final ImportFormNotifier formNotifier;
  final String? selectedColumn;
  final String? selectedTargetModel;
  final ValueChanged<String> onSelectColumn;

  final double minScale;
  final double maxScale;
  final bool showFullscreenButton;
  final VoidCallback? onOpenFullscreen;
  final bool isTablet;

  const MapperCanvasView({
    super.key,
    this.rootAnchorKey = 'importer.mapper.canvas',
    required this.theme,
    required this.options,
    required this.formState,
    required this.formNotifier,
    required this.selectedColumn,
    required this.selectedTargetModel,
    required this.onSelectColumn,
    this.minScale = 0.16,
    this.maxScale = 2.4,
    this.showFullscreenButton = true,
    this.onOpenFullscreen,
    this.isTablet = false,
  });

  @override
  State<MapperCanvasView> createState() => _MapperCanvasViewState();
}

class _MapperCanvasViewState extends State<MapperCanvasView>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _autoPanController;

  final GlobalKey _viewerStackKey = GlobalKey();

  final Set<String> _collapsedModels = {};
  final Set<String> _hiddenModels = {};
  final Map<String, Offset> _manualModelOffsets = {};

  List<String> _sourceColumnOrder = [];
  List<String> _targetModelOrder = [];

  bool _isDraggingSourceColumn = false;
  String? _draggedSourceColumn;
  String? _movingModelName;

  Offset _autoPanVelocity = Offset.zero;

  _CanvasModelLayoutMode _modelLayoutMode = _CanvasModelLayoutMode.vertical;
  int _modelGridColumns = 2;

  @override
  void initState() {
    super.initState();

    _modelGridColumns = widget.isTablet ? 1 : 2;

    _transformationController = TransformationController();

    _autoPanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_applyAutoPanTick);

    _syncLocalOrders();
  }

  @override
  void didUpdateWidget(covariant MapperCanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLocalOrders();
  }

  @override
  void dispose() {
    _stopAutoPan();
    _autoPanController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  double get _currentScale =>
      _transformationController.value.getMaxScaleOnAxis();

  void _syncLocalOrders() {
    final previewColumns = widget.formState.previewColumns.toList();

    _sourceColumnOrder = _mergeOrder(
      current: _sourceColumnOrder,
      available: previewColumns,
    );

    final selectedTargetModel = widget.selectedTargetModel?.trim();
    final allModelNames = widget.options.targetModels.keys.toList()..sort();

    _targetModelOrder = _mergeOrder(
      current: _targetModelOrder,
      available: allModelNames,
      preferredFirst:
          selectedTargetModel == null ||
              selectedTargetModel.isEmpty ||
              !allModelNames.contains(selectedTargetModel)
          ? const []
          : [selectedTargetModel],
    );

    final availableModelSet = allModelNames.toSet();

    _collapsedModels.removeWhere((model) => !availableModelSet.contains(model));
    _hiddenModels.removeWhere((model) => !availableModelSet.contains(model));

    _manualModelOffsets.removeWhere(
      (modelName, _) => !availableModelSet.contains(modelName),
    );

    if (_movingModelName != null &&
        !availableModelSet.contains(_movingModelName)) {
      _movingModelName = null;
    }
  }

  List<String> _mergeOrder({
    required List<String> current,
    required List<String> available,
    List<String> preferredFirst = const [],
  }) {
    final availableSet = available.toSet();

    if (available.isEmpty) {
      return <String>[];
    }

    if (current.isEmpty) {
      final result = <String>[];

      for (final item in preferredFirst) {
        if (availableSet.contains(item) && !result.contains(item)) {
          result.add(item);
        }
      }

      for (final item in available) {
        if (!result.contains(item)) {
          result.add(item);
        }
      }

      return result;
    }

    final result = current
        .where((item) => availableSet.contains(item))
        .toList(growable: true);

    for (final item in preferredFirst.reversed) {
      if (availableSet.contains(item)) {
        result.remove(item);
        result.insert(0, item);
      }
    }

    for (final item in available) {
      if (!result.contains(item)) {
        result.add(item);
      }
    }

    return result;
  }

  void _zoomBy(double factor) {
    final current = _currentScale;
    final target = (current * factor)
        .clamp(widget.minScale, widget.maxScale)
        .toDouble();
    final safeCurrent = current == 0 ? 1.0 : current;
    final ratio = target / safeCurrent;

    final nextMatrix = Matrix4.copy(_transformationController.value)
      ..scale(ratio);

    _transformationController.value = nextMatrix;
    setState(() {});
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
    setState(() {});
  }

  void _setDraggingSourceColumn(bool value, {String? column}) {
    if (_isDraggingSourceColumn == value && _draggedSourceColumn == column) {
      return;
    }

    setState(() {
      _isDraggingSourceColumn = value;
      _draggedSourceColumn = value ? column : null;
    });

    if (!value) {
      _stopAutoPan();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _updateAutoPan(details.globalPosition);
  }

  void _updateAutoPan(Offset globalPosition) {
    final context = _viewerStackKey.currentContext;
    if (context == null) return;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    final local = renderObject.globalToLocal(globalPosition);
    final size = renderObject.size;

    const edgeSize = 92.0;
    const maxVelocity = 24.0;

    double dx = 0;
    double dy = 0;

    if (local.dx < edgeSize) {
      dx =
          ((edgeSize - local.dx) / edgeSize).clamp(0.0, 1.0).toDouble() *
          maxVelocity;
    } else if (local.dx > size.width - edgeSize) {
      dx =
          -((local.dx - (size.width - edgeSize)) / edgeSize)
              .clamp(0.0, 1.0)
              .toDouble() *
          maxVelocity;
    }

    if (local.dy < edgeSize) {
      dy =
          ((edgeSize - local.dy) / edgeSize).clamp(0.0, 1.0).toDouble() *
          maxVelocity;
    } else if (local.dy > size.height - edgeSize) {
      dy =
          -((local.dy - (size.height - edgeSize)) / edgeSize)
              .clamp(0.0, 1.0)
              .toDouble() *
          maxVelocity;
    }

    _autoPanVelocity = Offset(dx, dy);

    if (_autoPanVelocity == Offset.zero) {
      _stopAutoPan(keepVelocity: false);
      return;
    }

    if (!_autoPanController.isAnimating) {
      _autoPanController.repeat();
    }
  }

  void _applyAutoPanTick() {
    if (_autoPanVelocity == Offset.zero) return;

    final next = Matrix4.copy(_transformationController.value);
    final storage = next.storage;

    storage[12] += _autoPanVelocity.dx;
    storage[13] += _autoPanVelocity.dy;

    _transformationController.value = next;
  }

  void _stopAutoPan({bool keepVelocity = false}) {
    if (!keepVelocity) {
      _autoPanVelocity = Offset.zero;
    }

    if (_autoPanController.isAnimating) {
      _autoPanController.stop();
    }
  }

  void _moveSourceColumnBefore({
    required String draggedColumn,
    required String targetColumn,
  }) {
    if (draggedColumn == targetColumn) return;

    setState(() {
      _sourceColumnOrder.remove(draggedColumn);

      final targetIndex = _sourceColumnOrder.indexOf(targetColumn);
      if (targetIndex < 0) {
        _sourceColumnOrder.add(draggedColumn);
      } else {
        _sourceColumnOrder.insert(targetIndex, draggedColumn);
      }
    });
  }

  void _moveTargetModelBefore({
    required String draggedModel,
    required String targetModel,
  }) {
    if (draggedModel == targetModel) return;

    setState(() {
      _targetModelOrder.remove(draggedModel);

      final targetIndex = _targetModelOrder.indexOf(targetModel);
      if (targetIndex < 0) {
        _targetModelOrder.add(draggedModel);
      } else {
        _targetModelOrder.insert(targetIndex, draggedModel);
      }
    });
  }

  void _moveTargetModelBy(String modelName, int delta) {
    final currentIndex = _targetModelOrder.indexOf(modelName);
    if (currentIndex < 0) return;

    final nextIndex = (currentIndex + delta)
        .clamp(0, _targetModelOrder.length - 1)
        .toInt();

    if (nextIndex == currentIndex) return;

    setState(() {
      final item = _targetModelOrder.removeAt(currentIndex);
      _targetModelOrder.insert(nextIndex, item);
    });
  }

  void _moveModelOnCanvas(String modelName, DragUpdateDetails details) {
    final scale = math.max(_currentScale, 0.0001);

    setState(() {
      final current = _manualModelOffsets[modelName] ?? Offset.zero;
      _manualModelOffsets[modelName] = current + details.delta / scale;
    });
  }

  void _startMovingModel(String modelName) {
    setState(() {
      _movingModelName = modelName;
    });
  }

  void _stopMovingModel() {
    if (_movingModelName == null) return;

    setState(() {
      _movingModelName = null;
    });
  }

  void _resetModelCanvasOffset(String modelName) {
    setState(() {
      _manualModelOffsets.remove(modelName);
    });
  }

  void _resetAllModelCanvasOffsets() {
    setState(() {
      _manualModelOffsets.clear();
    });
  }

  void _toggleModelCollapsed(String modelName) {
    setState(() {
      if (_collapsedModels.contains(modelName)) {
        _collapsedModels.remove(modelName);
      } else {
        _collapsedModels.add(modelName);
      }
    });
  }

  void _hideModel(String modelName) {
    setState(() {
      _hiddenModels.add(modelName);
    });
  }

  void _showAllModels() {
    setState(() {
      _hiddenModels.clear();
    });
  }

  void _expandAllModels() {
    setState(() {
      _collapsedModels.clear();
    });
  }

  void _collapseAllModels() {
    setState(() {
      _collapsedModels
        ..clear()
        ..addAll(_targetModelOrder);
    });
  }

  void _toggleModelLayoutMode() {
    setState(() {
      _modelLayoutMode = _modelLayoutMode == _CanvasModelLayoutMode.vertical
          ? _CanvasModelLayoutMode.grid
          : _CanvasModelLayoutMode.vertical;
    });
  }

  void _changeGridColumns(int delta) {
    setState(() {
      _modelGridColumns = (_modelGridColumns + delta)
          .clamp(widget.isTablet ? 1 : 2, 4)
          .toInt();
      _modelLayoutMode = _CanvasModelLayoutMode.grid;
    });
  }

  void _applyPayloadToTargetField({
    required _CanvasDragPayload payload,
    required String targetModel,
    required String targetField,
  }) {
    final columnName = payload.effectiveColumnName;
    if (columnName == null || columnName.isEmpty) return;

    widget.formNotifier.setMappingForTarget(
      columnName: columnName,
      targetModel: targetModel,
      targetField: targetField,
    );

    if (payload.isTargetField &&
        payload.modelName != null &&
        payload.fieldName != null &&
        (payload.modelName != targetModel ||
            payload.fieldName != targetField)) {
      widget.formNotifier.setMappingForTarget(
        columnName: null,
        targetModel: payload.modelName!,
        targetField: payload.fieldName!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncLocalOrders();

    final theme = widget.theme;
    final formState = widget.formState;
    final formNotifier = widget.formNotifier;

    final sourceColumns = _sourceColumnOrder
        .where((column) => formState.previewColumns.contains(column))
        .toList(growable: false);

    final selectedTargetModel = widget.selectedTargetModel?.trim();

    final modelNames = _targetModelOrder
        .where(
          (modelName) => widget.options.targetModels.containsKey(modelName),
        )
        .toList(growable: false);

    final visibleModelNames = modelNames
        .where((modelName) => !_hiddenModels.contains(modelName))
        .toList(growable: false);

    const double sourceX = 48;
    const double targetX = 760;
    const double sourceWidth = 270;
    const double targetWidth = 540;
    const double sourceHeight = 86;
    const double sourceGap = 16;
    const double targetGridGapX = 28;
    const double targetGridGapY = 26;

    final int modelColumnCount = _modelLayoutMode == _CanvasModelLayoutMode.grid
        ? math.min(_modelGridColumns, math.max(1, visibleModelNames.length))
        : 1;

    double computedCanvasWidth = _modelLayoutMode == _CanvasModelLayoutMode.grid
        ? targetX +
              (modelColumnCount * targetWidth) +
              ((modelColumnCount - 1) * targetGridGapX) +
              100
        : 1420;

    double computedModelCanvasBottom = 90;

    final Map<String, Rect> sourceRects = {};
    final Map<String, Rect> targetRects = {};
    final List<Widget> sourceWidgets = [];
    final List<Widget> targetWidgets = [];

    double sourceY = 90;

    for (final column in sourceColumns) {
      final rect = Rect.fromLTWH(sourceX, sourceY, sourceWidth, sourceHeight);
      sourceRects[column] = rect;

      final samples = _samplesForColumn(
        previewColumns: formState.previewColumns,
        previewData: formState.previewData,
        columnName: column,
      );

      final mappings = formState.fieldMappings
          .where((m) => m.columnName == column)
          .toList(growable: false);

      sourceWidgets.add(
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: DragTarget<_CanvasDragPayload>(
            onWillAcceptWithDetails: (details) {
              final payload = details.data;

              if (payload.isSourceColumn) {
                return payload.id != column;
              }

              if (payload.isTargetField) {
                return payload.modelName != null && payload.fieldName != null;
              }

              return false;
            },
            onAcceptWithDetails: (details) {
              final payload = details.data;

              if (payload.isSourceColumn) {
                _moveSourceColumnBefore(
                  draggedColumn: payload.id,
                  targetColumn: column,
                );
                return;
              }

              if (payload.isTargetField &&
                  payload.modelName != null &&
                  payload.fieldName != null) {
                formNotifier.setMappingForTarget(
                  columnName: column,
                  targetModel: payload.modelName!,
                  targetField: payload.fieldName!,
                );
              }
            },
            builder: (context, candidateData, rejectedData) {
              final payloads = candidateData.whereType<_CanvasDragPayload>();

              final isReorderHover = payloads.any(
                (payload) => payload.isSourceColumn && payload.id != column,
              );

              final isReverseMappingHover = payloads.any(
                (payload) => payload.isTargetField,
              );

              return LongPressDraggable<_CanvasDragPayload>(
                data: _CanvasDragPayload.sourceColumn(column),
                onDragStarted: () {
                  _setDraggingSourceColumn(true, column: column);
                },
                onDragUpdate: _handleDragUpdate,
                onDragCompleted: () {
                  _setDraggingSourceColumn(false);
                },
                onDraggableCanceled: (_, __) {
                  _setDraggingSourceColumn(false);
                },
                onDragEnd: (_) {
                  _setDraggingSourceColumn(false);
                },
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: rect.width,
                    child: _CanvasSourceNode(
                      theme: theme,
                      title: column,
                      samples: samples,
                      mappings: mappings,
                      isSelected: true,
                      isReorderHover: false,
                      isReverseMappingHover: false,
                      compact: true,
                      onTap: () {},
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.35,
                  child: _CanvasSourceNode(
                    theme: theme,
                    title: column,
                    samples: samples,
                    mappings: mappings,
                    isSelected: widget.selectedColumn == column,
                    isReorderHover: false,
                    isReverseMappingHover: false,
                    onTap: () => widget.onSelectColumn(column),
                  ),
                ),
                child: _CanvasSourceNode(
                  theme: theme,
                  title: column,
                  samples: samples,
                  mappings: mappings,
                  isSelected: widget.selectedColumn == column,
                  isReorderHover: isReorderHover,
                  isReverseMappingHover: isReverseMappingHover,
                  onTap: () => widget.onSelectColumn(column),
                ),
              );
            },
          ),
        ),
      );

      sourceY += sourceHeight + sourceGap;
    }

    final modelColumnYs = List<double>.filled(modelColumnCount, 90);

    for (final modelName in visibleModelNames) {
      final rawSpec = widget.options.targetModels[modelName];
      final fields = _extractFieldSpecsFromRawSpec(rawSpec);

      const double modelHeaderHeight = 48;
      const double fieldHeight = 64;
      const double fieldGap = 10;
      const double innerPadding = 12;

      final isCollapsed = _collapsedModels.contains(modelName);

      final mappedCount = formState.fieldMappings
          .where((mapping) => mapping.targetModel == modelName)
          .length;

      final double expandedModelHeight =
          modelHeaderHeight +
          innerPadding +
          (fields.length * (fieldHeight + fieldGap)) +
          8;

      final double modelHeight = isCollapsed ? 58 : expandedModelHeight;

      int layoutColumnIndex = 0;

      if (_modelLayoutMode == _CanvasModelLayoutMode.grid) {
        double minY = modelColumnYs.first;

        for (int i = 0; i < modelColumnYs.length; i++) {
          if (modelColumnYs[i] < minY) {
            minY = modelColumnYs[i];
            layoutColumnIndex = i;
          }
        }
      }

      final double baseModelX =
          targetX + layoutColumnIndex * (targetWidth + targetGridGapX);
      final double baseModelY = modelColumnYs[layoutColumnIndex];

      final modelOffset = _manualModelOffsets[modelName] ?? Offset.zero;

      final double modelX = baseModelX + modelOffset.dx;
      final double modelY = baseModelY + modelOffset.dy;

      modelColumnYs[layoutColumnIndex] += modelHeight + targetGridGapY;

      computedCanvasWidth = math.max(
        computedCanvasWidth,
        modelX + targetWidth + 140,
      );

      computedModelCanvasBottom = math.max(
        computedModelCanvasBottom,
        modelY + modelHeight + 140,
      );

      final isMainModel = selectedTargetModel == modelName;

      if (isCollapsed) {
        for (final spec in fields) {
          targetRects['$modelName.${spec.name}'] = Rect.fromLTWH(
            modelX + 14,
            modelY + 12,
            targetWidth - 28,
            modelHeaderHeight - 20,
          );
        }
      }

      targetWidgets.add(
        Positioned(
          left: modelX,
          top: modelY,
          width: targetWidth,
          height: modelHeight,
          child: DragTarget<_CanvasDragPayload>(
            onWillAcceptWithDetails: (details) {
              return details.data.isTargetModel && details.data.id != modelName;
            },
            onAcceptWithDetails: (details) {
              _moveTargetModelBefore(
                draggedModel: details.data.id,
                targetModel: modelName,
              );
            },
            builder: (context, candidateData, rejectedData) {
              final payloads = candidateData.whereType<_CanvasDragPayload>();

              final isModelReorderHover = payloads.any(
                (payload) => payload.isTargetModel && payload.id != modelName,
              );

              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: theme.dashboardContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isModelReorderHover
                        ? theme.themeColor
                        : isMainModel
                        ? theme.themeColor.withAlpha(180)
                        : theme.dashboardBoarder.withAlpha(110),
                    width: isModelReorderHover
                        ? 2
                        : isMainModel
                        ? 1.5
                        : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 9,
                      height: 34,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compactHeader = constraints.maxWidth < 540;
                          final hasManualOffset =
                              (_manualModelOffsets[modelName] ?? Offset.zero) !=
                              Offset.zero;

                          return Row(
                            children: [
                              _CanvasModelMoveHandle(
                                theme: theme,
                                isActive: _movingModelName == modelName,
                                onPanStart: () => _startMovingModel(modelName),
                                onPanUpdate: (details) =>
                                    _moveModelOnCanvas(modelName, details),
                                onPanEnd: _stopMovingModel,
                                onDoubleTap: () =>
                                    _resetModelCanvasOffset(modelName),
                              ),
                              const SizedBox(width: 4),
                              LongPressDraggable<_CanvasDragPayload>(
                                data: _CanvasDragPayload.targetModel(modelName),
                                onDragUpdate: _handleDragUpdate,
                                onDragEnd: (_) => _stopAutoPan(),
                                onDraggableCanceled: (_, __) => _stopAutoPan(),
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: _CanvasModelDragFeedback(
                                    theme: theme,
                                    modelName: modelName,
                                  ),
                                ),
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 19,
                                  color: theme.textColor.withAlpha(130),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  modelName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (!compactHeader && mappedCount > 0) ...[
                                const SizedBox(width: 8),
                                _CanvasHeaderBadge(
                                  theme: theme,
                                  label: '$mappedCount map.',
                                ),
                              ],
                              if (!compactHeader && isMainModel) ...[
                                const SizedBox(width: 8),
                                _CanvasHeaderBadge(
                                  theme: theme,
                                  label: 'GŁÓWNY'.tr,
                                  isPrimary: true,
                                ),
                              ],
                              const SizedBox(width: 4),
                              if (hasManualOffset)
                                _CanvasSmallIconButton(
                                  theme: theme,
                                  tooltip: 'Reset pozycji tej klasy'.tr,
                                  icon: Icons.my_location_rounded,
                                  onTap: () =>
                                      _resetModelCanvasOffset(modelName),
                                ),
                              _CanvasSmallIconButton(
                                theme: theme,
                                tooltip: 'Przenieś wyżej'.tr,
                                icon: Icons.keyboard_arrow_up_rounded,
                                onTap: () => _moveTargetModelBy(modelName, -1),
                              ),
                              _CanvasSmallIconButton(
                                theme: theme,
                                tooltip: 'Przenieś niżej'.tr,
                                icon: Icons.keyboard_arrow_down_rounded,
                                onTap: () => _moveTargetModelBy(modelName, 1),
                              ),
                              _CanvasSmallIconButton(
                                theme: theme,
                                tooltip: isCollapsed
                                    ? 'Rozwiń klasę'.tr
                                    : 'Zwiń klasę'.tr,
                                icon: isCollapsed
                                    ? Icons.unfold_more_rounded
                                    : Icons.unfold_less_rounded,
                                onTap: () => _toggleModelCollapsed(modelName),
                              ),
                              _CanvasSmallIconButton(
                                theme: theme,
                                tooltip: 'Ukryj klasę'.tr,
                                icon: Icons.close_rounded,
                                onTap: () => _hideModel(modelName),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (!isCollapsed)
                      ...List.generate(fields.length, (index) {
                        final spec = fields[index];
                        final top =
                            modelHeaderHeight +
                            innerPadding +
                            index * (fieldHeight + fieldGap);

                        final fieldRect = Rect.fromLTWH(
                          modelX + 14,
                          modelY + top,
                          targetWidth - 28,
                          fieldHeight,
                        );

                        targetRects['$modelName.${spec.name}'] = fieldRect;

                        final current = formNotifier.getMappingForTarget(
                          modelName,
                          spec.name,
                        );

                        final node = DragTarget<_CanvasDragPayload>(
                          onWillAcceptWithDetails: (details) {
                            final payload = details.data;

                            if (payload.isSourceColumn) return true;

                            if (payload.isTargetField) {
                              final sameField =
                                  payload.modelName == modelName &&
                                  payload.fieldName == spec.name;

                              return !sameField &&
                                  payload.effectiveColumnName != null;
                            }

                            return false;
                          },
                          onAcceptWithDetails: (details) {
                            _applyPayloadToTargetField(
                              payload: details.data,
                              targetModel: modelName,
                              targetField: spec.name,
                            );
                          },
                          builder: (context, candidateData, rejectedData) {
                            final payloads = candidateData
                                .whereType<_CanvasDragPayload>();

                            final isHovering = payloads.any(
                              (payload) =>
                                  payload.isSourceColumn ||
                                  payload.isTargetField,
                            );

                            return _CanvasTargetFieldNode(
                              theme: theme,
                              modelName: modelName,
                              fieldSpec: spec,
                              currentColumn: current?.columnName,
                              isHighlightedBySelectedColumn:
                                  widget.selectedColumn != null &&
                                  current?.columnName == widget.selectedColumn,
                              isDropHover: isHovering,
                              onTap: () {
                                if (widget.selectedColumn == null) return;

                                formNotifier.setMappingForTarget(
                                  columnName: widget.selectedColumn,
                                  targetModel: modelName,
                                  targetField: spec.name,
                                );
                              },
                              onClear: current == null
                                  ? null
                                  : () {
                                      formNotifier.setMappingForTarget(
                                        columnName: null,
                                        targetModel: modelName,
                                        targetField: spec.name,
                                      );
                                    },
                            );
                          },
                        );

                        return Positioned(
                          left: 14,
                          top: top,
                          width: targetWidth - 28,
                          height: fieldHeight,
                          child: LongPressDraggable<_CanvasDragPayload>(
                            data: _CanvasDragPayload.targetField(
                              modelName: modelName,
                              fieldName: spec.name,
                              columnName: current?.columnName,
                            ),
                            onDragUpdate: _handleDragUpdate,
                            onDragEnd: (_) => _stopAutoPan(),
                            onDraggableCanceled: (_, __) => _stopAutoPan(),
                            feedback: Material(
                              color: Colors.transparent,
                              child: _CanvasTargetFieldDragFeedback(
                                theme: theme,
                                modelName: modelName,
                                fieldSpec: spec,
                                currentColumn: current?.columnName,
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.38,
                              child: node,
                            ),
                            child: node,
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    final double maxTargetY = modelColumnYs.isEmpty
        ? 90
        : modelColumnYs.reduce((a, b) => math.max(a, b));

    final canvasWidth = computedCanvasWidth;

    final canvasHeight = math.max(
      sourceY + 120,
      math.max(maxTargetY + 80, computedModelCanvasBottom),
    );

    return EmmaUiAnchorTarget(
      anchorKey: widget.rootAnchorKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(Icons.hub_rounded, color: theme.themeColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Canvas mapper — przeciągaj kolumny i pola w obie strony, przesuwaj modele ręcznie, korzystaj z matchera oraz układaj modele pionowo albo obok siebie.'
                        .tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(190),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CanvasControlButton(
                  anchorKey: '${widget.rootAnchorKey}.layout_toggle',
                  theme: theme,
                  tooltip: _modelLayoutMode == _CanvasModelLayoutMode.grid
                      ? 'Układ pionowy'.tr
                      : 'Układ obok siebie'.tr,
                  icon: _modelLayoutMode == _CanvasModelLayoutMode.grid
                      ? Icons.view_agenda_rounded
                      : Icons.grid_view_rounded,
                  onTap: _toggleModelLayoutMode,
                ),
                if (_modelLayoutMode == _CanvasModelLayoutMode.grid) ...[
                  const SizedBox(width: 6),
                  _CanvasControlButton(
                    anchorKey: '${widget.rootAnchorKey}.grid_columns_minus',
                    theme: theme,
                    tooltip: 'Mniej kolumn modeli'.tr,
                    icon: Icons.remove_circle_outline,
                    onTap: () => _changeGridColumns(-1),
                  ),
                  const SizedBox(width: 6),
                  _CanvasControlButton(
                    anchorKey: '${widget.rootAnchorKey}.grid_columns_plus',
                    theme: theme,
                    tooltip: 'Więcej kolumn modeli'.tr,
                    icon: Icons.view_column_rounded,
                    onTap: () => _changeGridColumns(1),
                  ),
                ],
                if (_hiddenModels.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _CanvasControlButton(
                    anchorKey: '${widget.rootAnchorKey}.show_hidden',
                    theme: theme,
                    tooltip: 'Pokaż ukryte klasy'.tr,
                    icon: Icons.visibility_rounded,
                    onTap: _showAllModels,
                  ),
                ],
                const SizedBox(width: 6),
                _CanvasControlButton(
                  anchorKey: '${widget.rootAnchorKey}.expand_all',
                  theme: theme,
                  tooltip: 'Rozwiń wszystkie klasy'.tr,
                  icon: Icons.unfold_more_rounded,
                  onTap: _expandAllModels,
                ),
                const SizedBox(width: 6),
                _CanvasControlButton(
                  anchorKey: '${widget.rootAnchorKey}.collapse_all',
                  theme: theme,
                  tooltip: 'Zwiń wszystkie klasy'.tr,
                  icon: Icons.unfold_less_rounded,
                  onTap: _collapseAllModels,
                ),
                if (_manualModelOffsets.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _CanvasControlButton(
                    anchorKey: '${widget.rootAnchorKey}.reset_model_positions',
                    theme: theme,
                    tooltip: 'Reset pozycji modeli'.tr,
                    icon: Icons.restart_alt_rounded,
                    onTap: _resetAllModelCanvasOffsets,
                  ),
                ],
                const SizedBox(width: 6),
                _CanvasControlButton(
                  anchorKey: '${widget.rootAnchorKey}.zoom_out',
                  theme: theme,
                  tooltip: 'Oddal'.tr,
                  icon: Icons.remove_rounded,
                  onTap: () => _zoomBy(0.8),
                ),
                const SizedBox(width: 6),
                _CanvasControlButton(
                  anchorKey: '${widget.rootAnchorKey}.zoom_in',
                  theme: theme,
                  tooltip: 'Przybliż'.tr,
                  icon: Icons.add_rounded,
                  onTap: () => _zoomBy(1.25),
                ),
                const SizedBox(width: 6),
                _CanvasControlButton(
                  anchorKey: '${widget.rootAnchorKey}.reset_view',
                  theme: theme,
                  tooltip: 'Reset widoku'.tr,
                  icon: Icons.center_focus_strong_rounded,
                  onTap: _resetView,
                ),
                if (widget.showFullscreenButton &&
                    widget.onOpenFullscreen != null) ...[
                  const SizedBox(width: 6),
                  _CanvasControlButton(
                    anchorKey: '${widget.rootAnchorKey}.fullscreen',
                    theme: theme,
                    tooltip: 'Fullscreen'.tr,
                    icon: Icons.open_in_full_rounded,
                    onTap: widget.onOpenFullscreen!,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Stack(
              key: _viewerStackKey,
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: const EdgeInsets.all(900),
                  minScale: widget.isTablet
                      ? math.min(widget.minScale, 0.08)
                      : widget.minScale,
                  maxScale: widget.maxScale,
                  constrained: false,
                  child: SizedBox(
                    width: canvasWidth,
                    height: canvasHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MapperConnectionsPainter(
                              theme: theme,
                              mappings: formState.fieldMappings,
                              sourceRects: sourceRects,
                              targetRects: targetRects,
                              selectedColumn: widget.selectedColumn,
                            ),
                          ),
                        ),
                        ...sourceWidgets,
                        ...targetWidgets,
                      ],
                    ),
                  ),
                ),
                if (_isDraggingSourceColumn)
                  Positioned(
                    top: 12,
                    right: 12,
                    bottom: 58,
                    width: 380,
                    child: _CanvasQuickDropPanel(
                      theme: theme,
                      options: widget.options,
                      formNotifier: formNotifier,
                      modelNames: modelNames,
                      selectedTargetModel: selectedTargetModel,
                      collapsedModels: _collapsedModels,
                      hiddenModels: _hiddenModels,
                      activeSourceColumn: _draggedSourceColumn,
                      onDropDone: () => _setDraggingSourceColumn(false),
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: theme.dashboardContainer.withAlpha(235),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: theme.dashboardBoarder.withAlpha(120),
                      ),
                    ),
                    child: Text(
                      'Zoom ${(_currentScale * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _CanvasControlButton extends StatelessWidget {
  final String anchorKey;
  final ThemeColors theme;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _CanvasControlButton({
    required this.anchorKey,
    required this.theme,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EmmaUiAnchorTarget(
      anchorKey: anchorKey,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.dashboardContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dashboardBoarder.withAlpha(120)),
            ),
            child: Icon(icon, size: 18, color: theme.textColor),
          ),
        ),
      ),
    );
  }
}

class _CanvasSmallIconButton extends StatelessWidget {
  final ThemeColors theme;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _CanvasSmallIconButton({
    required this.theme,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(icon, size: 17, color: theme.textColor.withAlpha(160)),
        ),
      ),
    );
  }
}

class _CanvasModelMoveHandle extends StatelessWidget {
  final ThemeColors theme;
  final bool isActive;
  final VoidCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final VoidCallback onPanEnd;
  final VoidCallback onDoubleTap;

  const _CanvasModelMoveHandle({
    required this.theme,
    required this.isActive,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Przesuń model. Dwuklik resetuje pozycję.'.tr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => onPanStart(),
        onPanUpdate: onPanUpdate,
        onPanEnd: (_) => onPanEnd(),
        onPanCancel: onPanEnd,
        onDoubleTap: onDoubleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive
                ? theme.themeColor.withAlpha(28)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? theme.themeColor.withAlpha(130)
                  : Colors.transparent,
            ),
          ),
          child: Icon(
            Icons.open_with_rounded,
            size: 16,
            color: isActive ? theme.themeColor : theme.textColor.withAlpha(145),
          ),
        ),
      ),
    );
  }
}

class _CanvasHeaderBadge extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final bool isPrimary;

  const _CanvasHeaderBadge({
    required this.theme,
    required this.label,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 90),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isPrimary
              ? theme.themeColor.withAlpha(22)
              : theme.adPopBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isPrimary
                ? theme.themeColor.withAlpha(120)
                : theme.dashboardBoarder.withAlpha(80),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isPrimary
                ? theme.themeColor
                : theme.textColor.withAlpha(190),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CanvasModelDragFeedback extends StatelessWidget {
  final ThemeColors theme;
  final String modelName;

  const _CanvasModelDragFeedback({
    required this.theme,
    required this.modelName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(245),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.themeColor.withAlpha(150)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.drag_indicator_rounded, size: 18, color: theme.themeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              modelName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasTargetFieldDragFeedback extends StatelessWidget {
  final ThemeColors theme;
  final String modelName;
  final _TargetFieldSpec fieldSpec;
  final String? currentColumn;

  const _CanvasTargetFieldDragFeedback({
    required this.theme,
    required this.modelName,
    required this.fieldSpec,
    required this.currentColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.dashboardContainer.withAlpha(246),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.themeColor.withAlpha(140)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            fieldSpec.isRelation
                ? Icons.account_tree_rounded
                : Icons.label_outline_rounded,
            size: 16,
            color: fieldSpec.isRelation
                ? theme.themeColor
                : theme.textColor.withAlpha(150),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$modelName.${fieldSpec.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (currentColumn != null) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.adPopBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  currentColumn!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(210),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CanvasQuickDropPanel extends StatelessWidget {
  final ThemeColors theme;
  final ImportOptions options;
  final ImportFormNotifier formNotifier;
  final List<String> modelNames;
  final String? selectedTargetModel;
  final Set<String> collapsedModels;
  final Set<String> hiddenModels;
  final String? activeSourceColumn;
  final VoidCallback onDropDone;

  const _CanvasQuickDropPanel({
    required this.theme,
    required this.options,
    required this.formNotifier,
    required this.modelNames,
    required this.selectedTargetModel,
    required this.collapsedModels,
    required this.hiddenModels,
    required this.activeSourceColumn,
    required this.onDropDone,
  });

  @override
  Widget build(BuildContext context) {
    final activeColumn = activeSourceColumn;
    final sortedModelNames = modelNames.toList();

    if (activeColumn != null && activeColumn.isNotEmpty) {
      sortedModelNames.sort((a, b) {
        final aFields = _extractFieldSpecsFromRawSpec(options.targetModels[a]);
        final bFields = _extractFieldSpecsFromRawSpec(options.targetModels[b]);

        final aBest = _bestModelScore(activeColumn, aFields);
        final bBest = _bestModelScore(activeColumn, bFields);

        return bBest.compareTo(aBest);
      });
    }

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.dashboardContainer.withAlpha(246),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.themeColor.withAlpha(130),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.input_rounded, size: 18, color: theme.themeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeColumn == null
                        ? 'Szybki drop'.tr
                        : 'Szybki drop: $activeColumn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Najlepsze dopasowania są sortowane po podobieństwie nazw kluczy.'
                  .tr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor.withAlpha(160),
                fontSize: 10.5,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: sortedModelNames.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final modelName = sortedModelNames[index];
                  final rawSpec = options.targetModels[modelName];
                  final fields = _extractFieldSpecsFromRawSpec(rawSpec);

                  final isMain = selectedTargetModel == modelName;
                  final isCollapsed = collapsedModels.contains(modelName);
                  final isHidden = hiddenModels.contains(modelName);

                  return _CanvasQuickDropModelGroup(
                    theme: theme,
                    modelName: modelName,
                    fields: fields,
                    activeSourceColumn: activeColumn,
                    isMain: isMain,
                    isCollapsedOnCanvas: isCollapsed,
                    isHiddenOnCanvas: isHidden,
                    formNotifier: formNotifier,
                    onDropDone: onDropDone,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _bestModelScore(String sourceColumn, List<_TargetFieldSpec> fields) {
    if (fields.isEmpty) return 0;

    return fields
        .map((field) => _fieldSimilarityPercent(sourceColumn, field.name))
        .fold<int>(0, (best, score) => math.max(best, score));
  }
}

class _CanvasQuickDropModelGroup extends StatelessWidget {
  final ThemeColors theme;
  final String modelName;
  final List<_TargetFieldSpec> fields;
  final String? activeSourceColumn;
  final bool isMain;
  final bool isCollapsedOnCanvas;
  final bool isHiddenOnCanvas;
  final ImportFormNotifier formNotifier;
  final VoidCallback onDropDone;

  const _CanvasQuickDropModelGroup({
    required this.theme,
    required this.modelName,
    required this.fields,
    required this.activeSourceColumn,
    required this.isMain,
    required this.isCollapsedOnCanvas,
    required this.isHiddenOnCanvas,
    required this.formNotifier,
    required this.onDropDone,
  });

  @override
  Widget build(BuildContext context) {
    final sortedFields = fields.toList();
    final activeColumn = activeSourceColumn;

    if (activeColumn != null && activeColumn.isNotEmpty) {
      sortedFields.sort((a, b) {
        final aScore = _fieldSimilarityPercent(activeColumn, a.name);
        final bScore = _fieldSimilarityPercent(activeColumn, b.name);
        return bScore.compareTo(aScore);
      });
    }

    final bestScore = activeColumn == null || sortedFields.isEmpty
        ? 0
        : sortedFields
              .map((field) => _fieldSimilarityPercent(activeColumn, field.name))
              .fold<int>(0, (best, score) => math.max(best, score));

    return Container(
      decoration: BoxDecoration(
        color: theme.adPopBackground.withAlpha(190),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMain
              ? theme.themeColor.withAlpha(120)
              : theme.dashboardBoarder.withAlpha(90),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: isMain || bestScore >= 55,
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        iconColor: theme.textColor.withAlpha(180),
        collapsedIconColor: theme.textColor.withAlpha(130),
        title: Row(
          children: [
            Expanded(
              child: Text(
                modelName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (bestScore > 0) ...[
              const SizedBox(width: 5),
              _CanvasMatchBadge(theme: theme, score: bestScore),
            ],
            if (isMain) ...[
              const SizedBox(width: 5),
              _CanvasMiniBadge(
                theme: theme,
                label: 'GŁÓWNY'.tr,
                isPrimary: true,
              ),
            ],
            if (isCollapsedOnCanvas) ...[
              const SizedBox(width: 5),
              _CanvasMiniBadge(theme: theme, label: 'zwinięta'.tr),
            ],
            if (isHiddenOnCanvas) ...[
              const SizedBox(width: 5),
              _CanvasMiniBadge(theme: theme, label: 'ukryta'.tr),
            ],
          ],
        ),
        children: sortedFields.map((field) {
          final current = formNotifier.getMappingForTarget(
            modelName,
            field.name,
          );

          final score = activeColumn == null
              ? 0
              : _fieldSimilarityPercent(activeColumn, field.name);

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: DragTarget<_CanvasDragPayload>(
              onWillAcceptWithDetails: (details) {
                final payload = details.data;

                if (payload.isSourceColumn) return true;

                if (payload.isTargetField) {
                  final sameField =
                      payload.modelName == modelName &&
                      payload.fieldName == field.name;

                  return !sameField && payload.effectiveColumnName != null;
                }

                return false;
              },
              onAcceptWithDetails: (details) {
                final payload = details.data;
                final columnName = payload.effectiveColumnName;

                if (columnName == null || columnName.isEmpty) return;

                formNotifier.setMappingForTarget(
                  columnName: columnName,
                  targetModel: modelName,
                  targetField: field.name,
                );

                if (payload.isTargetField &&
                    payload.modelName != null &&
                    payload.fieldName != null &&
                    (payload.modelName != modelName ||
                        payload.fieldName != field.name)) {
                  formNotifier.setMappingForTarget(
                    columnName: null,
                    targetModel: payload.modelName!,
                    targetField: payload.fieldName!,
                  );
                }

                onDropDone();
              },
              builder: (context, candidateData, rejectedData) {
                final payloads = candidateData.whereType<_CanvasDragPayload>();

                final isHovering = payloads.any(
                  (payload) => payload.isSourceColumn || payload.isTargetField,
                );

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isHovering
                        ? theme.themeColor.withAlpha(24)
                        : score >= 75
                        ? theme.themeColor.withAlpha(13)
                        : theme.dashboardContainer.withAlpha(210),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: isHovering
                          ? theme.themeColor
                          : score >= 75
                          ? theme.themeColor.withAlpha(120)
                          : theme.dashboardBoarder.withAlpha(90),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        field.isRelation
                            ? Icons.account_tree_rounded
                            : Icons.label_outline_rounded,
                        size: 14,
                        color: field.isRelation
                            ? theme.themeColor
                            : theme.textColor.withAlpha(140),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              field.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (current?.columnName != null)
                              Text(
                                current!.columnName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.textColor.withAlpha(140),
                                  fontSize: 9,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (score > 0) ...[
                        const SizedBox(width: 6),
                        _CanvasMatchBadge(theme: theme, score: score),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        isHovering ? 'puść'.tr : 'drop'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isHovering
                              ? theme.themeColor
                              : theme.textColor.withAlpha(110),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CanvasMiniBadge extends StatelessWidget {
  final ThemeColors theme;
  final String label;
  final bool isPrimary;

  const _CanvasMiniBadge({
    required this.theme,
    required this.label,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 64),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isPrimary
              ? theme.themeColor.withAlpha(24)
              : theme.dashboardContainer.withAlpha(220),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isPrimary
                ? theme.themeColor.withAlpha(110)
                : theme.dashboardBoarder.withAlpha(80),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isPrimary
                ? theme.themeColor
                : theme.textColor.withAlpha(150),
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CanvasMatchBadge extends StatelessWidget {
  final ThemeColors theme;
  final int score;

  const _CanvasMatchBadge({required this.theme, required this.score});

  @override
  Widget build(BuildContext context) {
    final isStrong = score >= 75;
    final isMedium = score >= 45;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isStrong
            ? theme.themeColor.withAlpha(26)
            : isMedium
            ? theme.themeColor.withAlpha(14)
            : theme.dashboardContainer.withAlpha(220),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isStrong
              ? theme.themeColor.withAlpha(130)
              : isMedium
              ? theme.themeColor.withAlpha(80)
              : theme.dashboardBoarder.withAlpha(80),
        ),
      ),
      child: Text(
        '$score%',
        style: TextStyle(
          color: isMedium ? theme.themeColor : theme.textColor.withAlpha(140),
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CanvasSourceNode extends StatelessWidget {
  final ThemeColors theme;
  final String title;
  final List<String> samples;
  final List<FieldMappingRule> mappings;
  final bool isSelected;
  final bool isReorderHover;
  final bool isReverseMappingHover;
  final bool compact;
  final VoidCallback onTap;

  const _CanvasSourceNode({
    required this.theme,
    required this.title,
    required this.samples,
    required this.mappings,
    required this.isSelected,
    required this.isReorderHover,
    required this.isReverseMappingHover,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isReverseMappingHover
        ? theme.themeColor
        : isReorderHover
        ? theme.themeColor
        : isSelected
        ? theme.themeColor
        : theme.dashboardBoarder.withAlpha(110);

    final mappingSummary = mappings.isEmpty
        ? 'Niepołączona'.tr
        : '${mappings.length} map. • ${mappings.first.targetModel}.${mappings.first.targetField}${mappings.length > 1 ? ' +${mappings.length - 1}' : ''}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isReverseMappingHover
              ? theme.themeColor.withAlpha(28)
              : isReorderHover
              ? theme.themeColor.withAlpha(18)
              : isSelected
              ? theme.themeColor.withAlpha(24)
              : theme.dashboardContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected || isReorderHover || isReverseMappingHover
                ? 1.4
                : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.drag_indicator_rounded,
                  size: 16,
                  color: theme.textColor.withAlpha(120),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.table_rows_rounded,
                  size: 16,
                  color: theme.themeColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 7),
              Text(
                mappingSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: mappings.isEmpty
                      ? theme.textColor.withAlpha(150)
                      : theme.textColor.withAlpha(210),
                  fontSize: 10,
                  fontWeight: mappings.isEmpty
                      ? FontWeight.w500
                      : FontWeight.w700,
                ),
              ),
              if (samples.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  samples.take(2).join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(150),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CanvasTargetFieldNode extends StatelessWidget {
  final ThemeColors theme;
  final String modelName;
  final _TargetFieldSpec fieldSpec;
  final String? currentColumn;
  final bool isHighlightedBySelectedColumn;
  final bool isDropHover;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _CanvasTargetFieldNode({
    required this.theme,
    required this.modelName,
    required this.fieldSpec,
    required this.currentColumn,
    required this.isHighlightedBySelectedColumn,
    required this.isDropHover,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDropHover
              ? theme.themeColor.withAlpha(24)
              : isHighlightedBySelectedColumn
              ? theme.themeColor.withAlpha(16)
              : fieldSpec.isRelation
              ? theme.themeColor.withAlpha(8)
              : theme.adPopBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDropHover
                ? theme.themeColor
                : isHighlightedBySelectedColumn
                ? theme.themeColor.withAlpha(140)
                : fieldSpec.isRelation
                ? theme.themeColor.withAlpha(90)
                : theme.dashboardBoarder.withAlpha(100),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.drag_indicator_rounded,
              size: 14,
              color: theme.textColor.withAlpha(110),
            ),
            const SizedBox(width: 4),
            Icon(
              fieldSpec.isRelation
                  ? Icons.account_tree_rounded
                  : Icons.label_outline_rounded,
              size: 15,
              color: fieldSpec.isRelation
                  ? theme.themeColor
                  : theme.textColor.withAlpha(150),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fieldSpec.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (fieldSpec.isRelation)
                    Text(
                      fieldSpec.relatedModel == null
                          ? 'ForeignKey'
                          : 'FK → ${fieldSpec.relatedModel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.themeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            if (currentColumn != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.dashboardContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    currentColumn!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withAlpha(220),
                      fontSize: 10,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  'drop here'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor.withAlpha(130),
                    fontSize: 10,
                  ),
                ),
              ),
            if (onClear != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: theme.textColor.withAlpha(150),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapperConnectionsPainter extends CustomPainter {
  final ThemeColors theme;
  final List<FieldMappingRule> mappings;
  final Map<String, Rect> sourceRects;
  final Map<String, Rect> targetRects;
  final String? selectedColumn;

  _MapperConnectionsPainter({
    required this.theme,
    required this.mappings,
    required this.sourceRects,
    required this.targetRects,
    required this.selectedColumn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = theme.textColor.withAlpha(10)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (final mapping in mappings) {
      final sourceRect = sourceRects[mapping.columnName];
      final targetRect =
          targetRects['${mapping.targetModel}.${mapping.targetField}'];

      if (sourceRect == null || targetRect == null) continue;

      final start = Offset(
        sourceRect.right,
        sourceRect.top + sourceRect.height / 2,
      );
      final end = Offset(
        targetRect.left,
        targetRect.top + targetRect.height / 2,
      );

      final isHighlighted =
          selectedColumn != null && selectedColumn == mapping.columnName;

      final paint = Paint()
        ..color = isHighlighted
            ? theme.themeColor
            : theme.textColor.withAlpha(70)
        ..strokeWidth = isHighlighted ? 2.6 : 1.6
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + 120,
          start.dy,
          end.dx - 120,
          end.dy,
          end.dx,
          end.dy,
        );

      canvas.drawPath(path, paint);

      canvas.drawCircle(start, 3, Paint()..color = paint.color);

      canvas.drawCircle(end, 3, Paint()..color = paint.color);
    }
  }

  @override
  bool shouldRepaint(covariant _MapperConnectionsPainter oldDelegate) {
    return true;
  }
}

int _fieldSimilarityPercent(String left, String right) {
  final a = _normalizeMatcherKey(left);
  final b = _normalizeMatcherKey(right);

  if (a.isEmpty || b.isEmpty) return 0;
  if (a == b) return 100;

  final leftTokens = _matcherTokens(left);
  final rightTokens = _matcherTokens(right);

  int tokenScore = 0;

  if (leftTokens.isNotEmpty && rightTokens.isNotEmpty) {
    final intersection = leftTokens.intersection(rightTokens).length;
    final union = leftTokens.union(rightTokens).length;

    if (union > 0) {
      tokenScore = ((intersection / union) * 100).round();
    }
  }

  int containsScore = 0;

  if (a.contains(b) || b.contains(a)) {
    final shorter = math.min(a.length, b.length);
    final longer = math.max(a.length, b.length);
    containsScore = ((shorter / longer) * 92).round();
  }

  final distance = _levenshteinDistance(a, b);
  final maxLength = math.max(a.length, b.length);
  final editScore = maxLength == 0
      ? 0
      : (((maxLength - distance) / maxLength) * 100).round();

  final score = math.max(tokenScore, math.max(containsScore, editScore));

  return score.clamp(0, 100).toInt();
}

String _normalizeMatcherKey(String value) {
  return _stripMatcherDiacritics(
    value,
  ).trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

Set<String> _matcherTokens(String value) {
  final spacedCamel = value.trim().replaceAllMapped(
    RegExp(r'([a-ząćęłńóśźż0-9])([A-Z])', unicode: true),
    (match) => '${match.group(1)} ${match.group(2)}',
  );

  final normalized = _stripMatcherDiacritics(spacedCamel)
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-.]+'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ');

  return normalized
      .split(RegExp(r'\s+'))
      .map((token) => token.trim())
      .where((token) => token.length >= 2)
      .toSet();
}

String _stripMatcherDiacritics(String value) {
  const replacements = {
    'ą': 'a',
    'ć': 'c',
    'ę': 'e',
    'ł': 'l',
    'ń': 'n',
    'ó': 'o',
    'ś': 's',
    'ź': 'z',
    'ż': 'z',
    'Ą': 'A',
    'Ć': 'C',
    'Ę': 'E',
    'Ł': 'L',
    'Ń': 'N',
    'Ó': 'O',
    'Ś': 'S',
    'Ź': 'Z',
    'Ż': 'Z',
  };

  final buffer = StringBuffer();

  for (final codePoint in value.runes) {
    final char = String.fromCharCode(codePoint);
    buffer.write(replacements[char] ?? char);
  }

  return buffer.toString();
}

int _levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final previous = List<int>.generate(b.length + 1, (index) => index);
  final current = List<int>.filled(b.length + 1, 0);

  for (int i = 0; i < a.length; i++) {
    current[0] = i + 1;

    for (int j = 0; j < b.length; j++) {
      final insertCost = current[j] + 1;
      final deleteCost = previous[j + 1] + 1;
      final replaceCost =
          previous[j] + (a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1);

      current[j + 1] = math.min(insertCost, math.min(deleteCost, replaceCost));
    }

    for (int j = 0; j < previous.length; j++) {
      previous[j] = current[j];
    }
  }

  return previous[b.length];
}
