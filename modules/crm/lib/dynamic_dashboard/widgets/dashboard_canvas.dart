import 'dart:math';

import 'package:crm/dynamic_dashboard/models/dashboard_models.dart';
import 'package:crm/dynamic_dashboard/providers/dashboard_layout_provider.dart';
import 'package:crm/dynamic_dashboard/registry/dashboard_widget_registry.dart';
import 'package:crm/dynamic_dashboard/widgets/dashboard_widget_shell.dart';
import 'package:core/ui/anchors/anchor_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/theme/apptheme.dart';

class DashboardCanvas extends ConsumerStatefulWidget {
  const DashboardCanvas({
    super.key,
    required this.dashboardKey,
    required this.breakpoint,
  });

  final String dashboardKey;
  final DashboardBreakpoint breakpoint;

  @override
  ConsumerState<DashboardCanvas> createState() => _DashboardCanvasState();
}

class _DashboardCanvasState extends ConsumerState<DashboardCanvas> {
  final GlobalKey _stackKey = GlobalKey();
  _DragSession? _drag;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardLayoutProvider(widget.dashboardKey));
    final config = state.config;
    final registry = ref.watch(dashboardWidgetRegistryProvider);
    final theme = ref.watch(themeColorsProvider);

    if (config == null) return const SizedBox.shrink();

    final layout = config.layoutOf(widget.breakpoint);

    final items = layout.items.where((item) {
      final instance = config.findInstance(item.instanceId);
      if (instance == null) return false;
      if (!instance.isVisible) return false;

      final spec = registry.byType(instance.type);
      if (spec == null) return false;

      return true;
    }).toList(growable: false);

    if (items.isEmpty && !state.isLoading) {
      return EmmaUiAnchorTarget(
        // @emma-backend: DynamicDashboardEmmaAnchors.canvas(widget.dashboardKey)
        anchorKey: 'dynamic_dashboard.${widget.dashboardKey}.canvas',
        child: const SizedBox(
          height: 320,
          child: Center(
            child: Text('Dashboard is empty'),
          ),
        ),
      );
    }

    return EmmaUiAnchorTarget(
      // @emma-backend: DynamicDashboardEmmaAnchors.canvas(widget.dashboardKey)
      anchorKey: 'dynamic_dashboard.${widget.dashboardKey}.canvas',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final safeColumns = max(1, layout.columns);
          final totalGap = max(0, safeColumns - 1) * layout.gap;
          final availableWidth = max(
            0.0,
            constraints.maxWidth - (layout.horizontalPadding * 2) - totalGap,
          );
          final cellWidth = availableWidth / safeColumns;

          final maxRow =
              items.isEmpty ? 1 : items.map((e) => e.y + e.h).reduce(max);

          final canvasHeight =
              (layout.canvasPadding * 2) +
              (maxRow * layout.rowHeight) +
              max(0, maxRow - 1) * layout.gap;

          return SizedBox(
            height: max(canvasHeight, 320.0),
            child: Stack(
              key: _stackKey,
              clipBehavior: Clip.none,
              children: [
                if (state.isEditMode)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DashboardGridPainter(
                        columns: safeColumns,
                        cellWidth: cellWidth,
                        rowHeight: layout.rowHeight,
                        gap: layout.gap,
                        canvasPadding: layout.canvasPadding,
                        horizontalPadding: layout.horizontalPadding,
                        color: theme.dashboardBoarder,
                      ),
                    ),
                  ),
                for (final item in items)
                  Builder(
                    builder: (context) {
                      final instance = config.findInstance(item.instanceId)!;
                      final spec = registry.byType(instance.type)!;

                      return _DashboardTilePositioned(
                        dashboardKey: widget.dashboardKey,
                        breakpoint: widget.breakpoint,
                        item: item,
                        layout: layout,
                        instance: instance,
                        spec: spec,
                        cellWidth: cellWidth,
                        isGhosted: _drag?.instanceId == item.instanceId,
                        onDragStart: state.isEditMode
                            ? (details) => _handleDragStart(
                                  details: details,
                                  layout: layout,
                                  cellWidth: cellWidth,
                                  item: item,
                                )
                            : null,
                        onDragUpdate: state.isEditMode
                            ? (details) => _handleDragUpdate(
                                  details: details,
                                  layout: layout,
                                  cellWidth: cellWidth,
                                )
                            : null,
                        onDragEnd: state.isEditMode
                            ? (_) => _handleDragEnd()
                            : null,
                        onDragCancel:
                            state.isEditMode ? _handleDragCancel : null,
                      );
                    },
                  ),
                if (_drag != null) ...[
                  _buildDropPreview(
                    layout: layout,
                    cellWidth: cellWidth,
                    drag: _drag!,
                  ),
                  _buildGhost(
                    layout: layout,
                    cellWidth: cellWidth,
                    registry: registry,
                    config: config,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleDragStart({
    required DragStartDetails details,
    required DashboardBreakpointLayout layout,
    required double cellWidth,
    required DashboardLayoutItem item,
  }) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final canvasPosition = box.globalToLocal(details.globalPosition);
    final ghostTopLeft = canvasPosition - details.localPosition;
    final preview = _snapItemToGrid(
      item: item,
      ghostTopLeft: ghostTopLeft,
      layout: layout,
      cellWidth: cellWidth,
    );

    setState(() {
      _drag = _DragSession(
        instanceId: item.instanceId,
        originItem: item,
        previewItem: preview,
        pointerOffsetInTile: details.localPosition,
        ghostTopLeft: ghostTopLeft,
      );
    });
  }

  void _handleDragUpdate({
    required DragUpdateDetails details,
    required DashboardBreakpointLayout layout,
    required double cellWidth,
  }) {
    final current = _drag;
    if (current == null) return;

    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final canvasPosition = box.globalToLocal(details.globalPosition);
    final ghostTopLeft = canvasPosition - current.pointerOffsetInTile;

    final preview = _snapItemToGrid(
      item: current.originItem,
      ghostTopLeft: ghostTopLeft,
      layout: layout,
      cellWidth: cellWidth,
    );

    setState(() {
      _drag = current.copyWith(
        ghostTopLeft: ghostTopLeft,
        previewItem: preview,
      );
    });
  }

  void _handleDragEnd() {
    final current = _drag;
    if (current == null) return;

    final notifier =
        ref.read(dashboardLayoutProvider(widget.dashboardKey).notifier);

    final origin = current.originItem;
    final target = current.previewItem;

    if (origin.x != target.x || origin.y != target.y) {
      notifier.moveItem(
        breakpoint: widget.breakpoint,
        instanceId: current.instanceId,
        x: target.x,
        y: target.y,
      );
      notifier.scheduleSave();
    }

    setState(() {
      _drag = null;
    });
  }

  void _handleDragCancel() {
    setState(() {
      _drag = null;
    });
  }

  DashboardLayoutItem _snapItemToGrid({
    required DashboardLayoutItem item,
    required Offset ghostTopLeft,
    required DashboardBreakpointLayout layout,
    required double cellWidth,
  }) {
    final stepX = cellWidth + layout.gap;
    final stepY = layout.rowHeight + layout.gap;

    final rawX = ((ghostTopLeft.dx - layout.horizontalPadding) / stepX).round();
    final rawY = ((ghostTopLeft.dy - layout.canvasPadding) / stepY).round();

    final clampedX = rawX.clamp(0, max(0, layout.columns - item.w)).toInt();
    final clampedY = max(0, rawY);

    return item.copyWith(
      x: clampedX,
      y: clampedY,
    );
  }

  Widget _buildDropPreview({
    required DashboardBreakpointLayout layout,
    required double cellWidth,
    required _DragSession drag,
  }) {
    final item = drag.previewItem;
    final theme = ref.read(themeColorsProvider);

    final left = layout.horizontalPadding + item.x * (cellWidth + layout.gap);
    final top = layout.canvasPadding + item.y * (layout.rowHeight + layout.gap);
    final width = item.w * cellWidth + max(0, item.w - 1) * layout.gap;
    final height =
        item.h * layout.rowHeight + max(0, item.h - 1) * layout.gap;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.dashboardContainer.withAlpha(120),
            border: Border.all(
              color: theme.dashboardBoarder,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGhost({
    required DashboardBreakpointLayout layout,
    required double cellWidth,
    required DashboardWidgetRegistry registry,
    required DashboardConfig config,
  }) {
    final drag = _drag!;
    final instance = config.findInstance(drag.instanceId);
    if (instance == null) return const SizedBox.shrink();

    final spec = registry.byType(instance.type);
    if (spec == null) return const SizedBox.shrink();

    final width = drag.originItem.w * cellWidth +
        max(0, drag.originItem.w - 1) * layout.gap;

    final height = drag.originItem.h * layout.rowHeight +
        max(0, drag.originItem.h - 1) * layout.gap;

    return Positioned(
      left: drag.ghostTopLeft.dx,
      top: drag.ghostTopLeft.dy,
      width: width,
      height: height,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.82,
          child: Transform.scale(
            scale: 1.02,
            child: _DashboardGhostCard(
              title: instance.titleOverride ?? spec.title,
              icon: spec.icon,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardGhostCard extends ConsumerWidget {
  const _DashboardGhostCard({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeColorsProvider);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.dashboardContainer.withAlpha(200),
        border: Border.all(
          color: theme.dashboardBoarder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: theme.textColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: Icon(
                Icons.dashboard_customize_rounded,
                size: 34,
                color: theme.textColor.withAlpha(140),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _DashboardTilePositioned extends StatelessWidget {
  const _DashboardTilePositioned({
    required this.dashboardKey,
    required this.breakpoint,
    required this.item,
    required this.layout,
    required this.instance,
    required this.spec,
    required this.cellWidth,
    required this.isGhosted,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final String dashboardKey;
  final DashboardBreakpoint breakpoint;
  final DashboardLayoutItem item;
  final DashboardBreakpointLayout layout;
  final DashboardWidgetInstance instance;
  final DashboardWidgetSpec spec;
  final double cellWidth;
  final bool isGhosted;

  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;
  final VoidCallback? onDragCancel;

  @override
  Widget build(BuildContext context) {
    final left = layout.horizontalPadding + item.x * (cellWidth + layout.gap);
    final top = layout.canvasPadding + item.y * (layout.rowHeight + layout.gap);
    final width = item.w * cellWidth + max(0, item.w - 1) * layout.gap;
    final height = item.h * layout.rowHeight + max(0, item.h - 1) * layout.gap;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: EmmaUiAnchorTarget(
        // @emma-backend: DynamicDashboardEmmaAnchors.tile(
        //   dashboardKey: dashboardKey,
        //   instanceId: instance.id,
        //   widgetType: instance.type,
        //   title: instance.titleOverride ?? spec.title,
        // )
        anchorKey: 'dynamic_dashboard.$dashboardKey.tile.${instance.id}',
        child: _DashboardTile(
          dashboardKey: dashboardKey,
          breakpoint: breakpoint,
          item: item,
          layout: layout,
          instance: instance,
          spec: spec,
          cellWidth: cellWidth,
          isGhosted: isGhosted,
          onDragStart: onDragStart,
          onDragUpdate: onDragUpdate,
          onDragEnd: onDragEnd,
          onDragCancel: onDragCancel,
        ),
      ),
    );
  }
}

enum _ResizeHorizontal { left, right, none }
enum _ResizeVertical { top, bottom, none }

class _DashboardTile extends ConsumerStatefulWidget {
  const _DashboardTile({
    required this.dashboardKey,
    required this.breakpoint,
    required this.item,
    required this.layout,
    required this.instance,
    required this.spec,
    required this.cellWidth,
    required this.isGhosted,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final String dashboardKey;
  final DashboardBreakpoint breakpoint;
  final DashboardLayoutItem item;
  final DashboardBreakpointLayout layout;
  final DashboardWidgetInstance instance;
  final DashboardWidgetSpec spec;
  final double cellWidth;
  final bool isGhosted;

  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;
  final VoidCallback? onDragCancel;

  @override
  ConsumerState<_DashboardTile> createState() => _DashboardTileState();
}

class _DashboardTileState extends ConsumerState<_DashboardTile> {
  Offset? _resizeStart;
  late DashboardLayoutItem _resizeOrigin;

  double get _stepX => widget.cellWidth + widget.layout.gap;
  double get _stepY => widget.layout.rowHeight + widget.layout.gap;

  int _clampInt(int value, int minValue, int maxValue) {
    if (maxValue < minValue) return minValue;
    return value.clamp(minValue, maxValue).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardLayoutProvider(widget.dashboardKey));
    final notifier =
        ref.read(dashboardLayoutProvider(widget.dashboardKey).notifier);

    final shell = DashboardWidgetShell(
      title: widget.instance.titleOverride ?? widget.spec.title,
      isEditMode: state.isEditMode,
      onRemove: () => notifier.removeWidget(widget.instance.id),
      onDuplicate: () => notifier.duplicateWidget(
        breakpoint: widget.breakpoint,
        instanceId: widget.instance.id,
      ),
      onSettings: widget.spec.hasSettings
          ? () => _openWidgetSettingsSheet(
                context: context,
                notifier: notifier,
              )
          : null,
      handles: state.isEditMode && widget.spec.canResize
          ? _buildHandles(notifier)
          : const [],
      child: widget.spec.buildWithDashboardKey(
        context,
        ref,
        widget.instance,
        widget.breakpoint,
        state.isEditMode,
        widget.dashboardKey,
      ),
    );

    final isDraggable = state.isEditMode && widget.spec.canMove;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: widget.isGhosted ? 0.22 : 1,
      child: isDraggable
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: widget.onDragStart,
              onPanUpdate: widget.onDragUpdate,
              onPanEnd: widget.onDragEnd,
              onPanCancel: widget.onDragCancel,
              child: shell,
            )
          : shell,
    );
  }

  Future<void> _openWidgetSettingsSheet({
  required BuildContext context,
  required DashboardLayoutNotifier notifier,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.28,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: ref.read(themeColorsProvider).dashboardContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                Row(
                  children: [
                    Icon(widget.spec.icon, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.instance.titleOverride ?? widget.spec.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                widget.spec.buildSettingsPanel(
                  context,
                  ref,
                  widget.instance,
                  (nextSettings) {
                    notifier.updateWidgetSettings(
                      instanceId: widget.instance.id,
                      settings: nextSettings,
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  List<Widget> _buildHandles(DashboardLayoutNotifier notifier) {
    return [
      _resizeHandle(
        alignment: Alignment.centerLeft,
        width: 16,
        height: double.infinity,
        h: _ResizeHorizontal.left,
        v: _ResizeVertical.none,
        cursor: SystemMouseCursors.resizeLeftRight,
        notifier: notifier,
      ),
      _resizeHandle(
        alignment: Alignment.centerRight,
        width: 16,
        height: double.infinity,
        h: _ResizeHorizontal.right,
        v: _ResizeVertical.none,
        cursor: SystemMouseCursors.resizeLeftRight,
        notifier: notifier,
      ),
      _resizeHandle(
        alignment: Alignment.topCenter,
        width: double.infinity,
        height: 16,
        h: _ResizeHorizontal.none,
        v: _ResizeVertical.top,
        cursor: SystemMouseCursors.resizeUpDown,
        notifier: notifier,
      ),
      _resizeHandle(
        alignment: Alignment.bottomCenter,
        width: double.infinity,
        height: 16,
        h: _ResizeHorizontal.none,
        v: _ResizeVertical.bottom,
        cursor: SystemMouseCursors.resizeUpDown,
        notifier: notifier,
      ),
      _resizeHandle(
        alignment: Alignment.topLeft,
        width: 20,
        height: 20,
        h: _ResizeHorizontal.left,
        v: _ResizeVertical.top,
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        notifier: notifier,
      ),
      _resizeHandle(
        alignment: Alignment.topRight,
        width: 20,
        height: 20,
        h: _ResizeHorizontal.right,
        v: _ResizeVertical.top,
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        notifier: notifier,
      ),
      _resizeHandle(
        alignment: Alignment.bottomLeft,
        width: 20,
        height: 20,
        h: _ResizeHorizontal.left,
        v: _ResizeVertical.bottom,
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        notifier: notifier,
      ),
      _resizeHandle(
        alignment: Alignment.bottomRight,
        width: 20,
        height: 20,
        h: _ResizeHorizontal.right,
        v: _ResizeVertical.bottom,
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        notifier: notifier,
      ),
    ];
  }

  Widget _resizeHandle({
    required Alignment alignment,
    required double width,
    required double height,
    required _ResizeHorizontal h,
    required _ResizeVertical v,
    required MouseCursor cursor,
    required DashboardLayoutNotifier notifier,
  }) {
    return Align(
      alignment: alignment,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            _resizeStart = details.globalPosition;
            _resizeOrigin = widget.item;
          },
          onPanUpdate: (details) {
            if (_resizeStart == null) return;

            final delta = details.globalPosition - _resizeStart!;
            final dx = (delta.dx / _stepX).round();
            final dy = (delta.dy / _stepY).round();

            final next = _calculateResize(
              origin: _resizeOrigin,
              horizontal: h,
              vertical: v,
              dx: dx,
              dy: dy,
            );

            notifier.resizeItem(
              breakpoint: widget.breakpoint,
              instanceId: widget.instance.id,
              x: next.x,
              y: next.y,
              w: next.w,
              h: next.h,
            );
          },
          onPanEnd: (_) {
            _resizeStart = null;
            notifier.scheduleSave();
          },
          child: SizedBox(
            width: width == double.infinity ? double.maxFinite : width,
            height: height == double.infinity ? double.maxFinite : height,
          ),
        ),
      ),
    );
  }

  DashboardLayoutItem _calculateResize({
    required DashboardLayoutItem origin,
    required _ResizeHorizontal horizontal,
    required _ResizeVertical vertical,
    required int dx,
    required int dy,
  }) {
    final c = widget.spec.constraints;

    int x = origin.x;
    int y = origin.y;
    int w = origin.w;
    int h = origin.h;

    if (horizontal == _ResizeHorizontal.right) {
      w = origin.w + dx;
    } else if (horizontal == _ResizeHorizontal.left) {
      x = origin.x + dx;
      w = origin.w - dx;
    }

    if (vertical == _ResizeVertical.bottom) {
      h = origin.h + dy;
    } else if (vertical == _ResizeVertical.top) {
      y = origin.y + dy;
      h = origin.h - dy;
    }

    final maxAllowedW = min(c.maxW, widget.layout.columns);

    if (w < c.minW) {
      if (horizontal == _ResizeHorizontal.left) {
        x -= (c.minW - w);
      }
      w = c.minW;
    }
    if (w > maxAllowedW) {
      if (horizontal == _ResizeHorizontal.left) {
        x += (w - maxAllowedW);
      }
      w = maxAllowedW;
    }

    if (h < c.minH) {
      if (vertical == _ResizeVertical.top) {
        y -= (c.minH - h);
      }
      h = c.minH;
    }
    if (h > c.maxH) {
      if (vertical == _ResizeVertical.top) {
        y += (h - c.maxH);
      }
      h = c.maxH;
    }

    if (x < 0) {
      w += x;
      x = 0;
    }
    if (y < 0) {
      h += y;
      y = 0;
    }

    w = _clampInt(w, c.minW, maxAllowedW);
    h = _clampInt(h, c.minH, c.maxH);

    if (x + w > widget.layout.columns) {
      if (horizontal == _ResizeHorizontal.left) {
        x = max(0, widget.layout.columns - w);
      } else {
        w = widget.layout.columns - x;
      }
    }

    w = _clampInt(w, c.minW, maxAllowedW);
    h = _clampInt(h, c.minH, c.maxH);

    return origin.copyWith(
      x: x,
      y: y,
      w: w,
      h: h,
    );
  }
}

class _DragSession {
  final String instanceId;
  final DashboardLayoutItem originItem;
  final DashboardLayoutItem previewItem;
  final Offset pointerOffsetInTile;
  final Offset ghostTopLeft;

  const _DragSession({
    required this.instanceId,
    required this.originItem,
    required this.previewItem,
    required this.pointerOffsetInTile,
    required this.ghostTopLeft,
  });

  _DragSession copyWith({
    String? instanceId,
    DashboardLayoutItem? originItem,
    DashboardLayoutItem? previewItem,
    Offset? pointerOffsetInTile,
    Offset? ghostTopLeft,
  }) {
    return _DragSession(
      instanceId: instanceId ?? this.instanceId,
      originItem: originItem ?? this.originItem,
      previewItem: previewItem ?? this.previewItem,
      pointerOffsetInTile: pointerOffsetInTile ?? this.pointerOffsetInTile,
      ghostTopLeft: ghostTopLeft ?? this.ghostTopLeft,
    );
  }
}

class _DashboardGridPainter extends CustomPainter {
  _DashboardGridPainter({
    required this.columns,
    required this.cellWidth,
    required this.rowHeight,
    required this.gap,
    required this.canvasPadding,
    required this.horizontalPadding,
    required this.color,
  });

  final int columns;
  final double cellWidth;
  final double rowHeight;
  final double gap;
  final double canvasPadding;
  final double horizontalPadding;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final usableHeight = max(0.0, size.height - (canvasPadding * 2));
    final rows = ((usableHeight + gap) / (rowHeight + gap)).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        final left = horizontalPadding + col * (cellWidth + gap);
        final top = canvasPadding + row * (rowHeight + gap);

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, cellWidth, rowHeight),
          const Radius.circular(12),
        );

        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardGridPainter oldDelegate) {
    return oldDelegate.columns != columns ||
        oldDelegate.cellWidth != cellWidth ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.gap != gap ||
        oldDelegate.canvasPadding != canvasPadding ||
        oldDelegate.horizontalPadding != horizontalPadding ||
        oldDelegate.color != color;
  }
}