part of 'floor_plan_canvas.dart';

class _Toolbar extends ConsumerWidget {
  final FloorPlanTool selectedTool;
  final FloorPlanAssetType selectedAssetType;

  final bool isSaving;
  final bool isDirty;
  final String? saveStatusLabel;
  final Future<void> Function()? onSave;
  final Future<void> Function()? onReload;
  final VoidCallback? onGeneratePlan;
  final Future<void> Function(FloorPlanExportFormat format)? onExport;
  final VoidCallback? onOpen3d;

  final bool angleLockEnabled;
  final double angleStepDegrees;
  final bool continuousDrawingEnabled;
  final bool smartGuidesEnabled;
  final bool cornerAnglesVisible;
  final bool roomLabelsVisible;
  final bool roomAreasVisible;

  final double zoomScale;
  final double rotationDegrees;
  final bool canUndo;
  final bool canRedo;

  final ValueChanged<FloorPlanTool> onToolChanged;
  final ValueChanged<FloorPlanAssetType> onAssetTypeChanged;

  final ValueChanged<bool> onAngleLockChanged;
  final ValueChanged<double?> onAngleStepChanged;
  final ValueChanged<bool> onContinuousDrawingChanged;
  final ValueChanged<bool> onSmartGuidesChanged;
  final ValueChanged<bool> onCornerAnglesVisibleChanged;
  final ValueChanged<bool> onRoomLabelsVisibleChanged;
  final ValueChanged<bool> onRoomAreasVisibleChanged;

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetView;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onResetRotation;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const _Toolbar({
    required this.selectedTool,
    required this.selectedAssetType,
    required this.isSaving,
    required this.isDirty,
    this.saveStatusLabel,
    this.onSave,
    this.onReload,
    this.onGeneratePlan,
    this.onExport,
    this.onOpen3d,
    required this.angleLockEnabled,
    required this.angleStepDegrees,
    required this.continuousDrawingEnabled,
    required this.smartGuidesEnabled,
    required this.cornerAnglesVisible,
    required this.roomLabelsVisible,
    required this.roomAreasVisible,
    required this.zoomScale,
    required this.rotationDegrees,
    required this.canUndo,
    required this.canRedo,
    required this.onToolChanged,
    required this.onAssetTypeChanged,
    required this.onAngleLockChanged,
    required this.onAngleStepChanged,
    required this.onContinuousDrawingChanged,
    required this.onSmartGuidesChanged,
    required this.onCornerAnglesVisibleChanged,
    required this.onRoomLabelsVisibleChanged,
    required this.onRoomAreasVisibleChanged,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetView,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onResetRotation,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    final zoomLabel = '${(zoomScale * 100).toStringAsFixed(0)}%';
    final rotationLabel = '${rotationDegrees.toStringAsFixed(0)}°';

    if (isMobile) return _buildMobileBar(context, theme, zoomLabel);

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border(
          bottom: BorderSide(color: theme.dashboardBoarder),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _ToolbarBrand(theme: theme),
          const SizedBox(width: 10),
       
          _ToolbarGroup(
            theme: theme,
            children: [
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.undo,
                tooltip: 'undo_tooltip'.tr,
                onPressed: canUndo ? onUndo : null,
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.redo,
                tooltip: 'redo_tooltip'.tr,
                onPressed: canRedo ? onRedo : null,
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToolbarGroup(
                    theme: theme,
                    label: 'tools_label'.tr,
                    children: [
                      _ToolButton(
                        theme: theme,
                        selected: selectedTool == FloorPlanTool.select,
                        icon: Icons.near_me_outlined,
                        label: 'select_tool_label'.tr,
                        tooltip:
                            'select_tool_tooltip'.tr,
                        onTap: () => onToolChanged(FloorPlanTool.select),
                      ),
                      _ToolButton(
                        theme: theme,
                        selected: selectedTool == FloorPlanTool.wall,
                        icon: Icons.show_chart,
                        label: 'wall_tool_label'.tr,
                        tooltip:
                            'wall_tool_tooltip'.tr,
                        onTap: () => onToolChanged(FloorPlanTool.wall),
                      ),
                      _ToolButton(
                        theme: theme,
                        selected: selectedTool == FloorPlanTool.virtualWall,
                        icon: Icons.border_style,
                        label: 'virtual_wall_tool_label'.tr,
                        tooltip:
                            'virtual_wall_tool_tooltip'.tr,
                        onTap: () => onToolChanged(FloorPlanTool.virtualWall),
                      ),
                      _ToolButton(
                        theme: theme,
                        selected: selectedTool == FloorPlanTool.room,
                        icon: Icons.crop_square,
                        label: 'room_tool_label'.tr,
                        tooltip:
                            'room_tool_tooltip'.tr,
                        onTap: () => onToolChanged(FloorPlanTool.room),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  _ToolbarGroup(
                    theme: theme,
                    label: 'openings_label'.tr,
                    children: [
                      _ToolButton(
                        theme: theme,
                        selected: selectedTool == FloorPlanTool.door,
                        icon: Icons.meeting_room_outlined,
                        label: 'door_tool_label'.tr,
                        tooltip:
                            'door_tool_tooltip'.tr,
                        onTap: () => onToolChanged(FloorPlanTool.door),
                      ),
                      _ToolButton(
                        theme: theme,
                        selected: selectedTool == FloorPlanTool.window,
                        icon: Icons.window_outlined,
                        label: 'window_tool_label'.tr,
                        tooltip:
                            'window_tool_tooltip'.tr,
                        onTap: () => onToolChanged(FloorPlanTool.window),
                      ),
                      _ToolButton(
                        theme: theme,
                        selected: selectedTool == FloorPlanTool.garageDoor,
                        icon: Icons.garage_outlined,
                        label: 'garage_door_tool_label'.tr,
                        tooltip:
                            'garage_door_tool_tooltip'.tr,
                        onTap: () => onToolChanged(FloorPlanTool.garageDoor),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  _ToolbarGroup(
                    theme: theme,
                    label: 'assets_label'.tr,
                    children: [
                      _ToolButton(
                        theme: theme,
                        selected: selectedTool == FloorPlanTool.asset,
                        icon: Icons.weekend_outlined,
                        label: 'add_asset_tool_label'.tr,
                        tooltip:
                            'add_asset_tool_tooltip'.tr,
                        onTap: () => onToolChanged(FloorPlanTool.asset),
                      ),
                      _AssetTypeSelector(
                        theme: theme,
                        selectedAssetType: selectedAssetType,
                        onChanged: onAssetTypeChanged,
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  _ToolbarGroup(
                    theme: theme,
                    label: 'view_label'.tr,
                    children: [
                      _ToolbarIconButton(
                        theme: theme,
                        icon: Icons.zoom_out,
                        tooltip: 'zoom_out_tooltip'.tr,
                        onPressed: onZoomOut,
                      ),
                      _ToolbarValueChip(
                        theme: theme,
                        value: zoomLabel,
                        tooltip: 'current_zoom_tooltip'.tr,
                      ),
                      _ToolbarIconButton(
                        theme: theme,
                        icon: Icons.zoom_in,
                        tooltip: 'zoom_in_tooltip'.tr,
                        onPressed: onZoomIn,
                      ),
                      _ToolbarIconButton(
                        theme: theme,
                        icon: Icons.fit_screen_outlined,
                        tooltip: 'reset_view_tooltip'.tr,
                        onPressed: onResetView,
                      ),
                      const SizedBox(width: 6),
                      _ToolbarIconButton(
                        theme: theme,
                        icon: Icons.rotate_left,
                        tooltip: 'rotate_view_left_tooltip'.tr,
                        onPressed: onRotateLeft,
                      ),
                      _ToolbarValueChip(
                        theme: theme,
                        value: rotationLabel,
                        tooltip: 'current_rotation_tooltip'.tr,
                        minWidth: 46,
                      ),
                      _ToolbarIconButton(
                        theme: theme,
                        icon: Icons.rotate_right,
                        tooltip:'rotate_view_right_tooltip'.tr,
                        onPressed: onRotateRight,
                      ),
                      _ToolbarIconButton(
                        theme: theme,
                        icon: Icons.restart_alt,
                        tooltip: 'reset_rotation_tooltip'.tr,
                        onPressed: onResetRotation,
                      ),
                      _ToolButton(
                        theme: theme,
                        selected: selectedTool == FloorPlanTool.pan,
                        icon: Icons.pan_tool_alt_outlined,
                        label: 'pan_tool_label'.tr,
                        tooltip:
                            'pan_tool_tooltip'.tr,
                        onTap: () => onToolChanged(FloorPlanTool.pan),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  _ToolbarSettingsMenu(
                    theme: theme,
                    angleLockEnabled: angleLockEnabled,
                    angleStepDegrees: angleStepDegrees,
                    continuousDrawingEnabled: continuousDrawingEnabled,
                    smartGuidesEnabled: smartGuidesEnabled,
                    cornerAnglesVisible: cornerAnglesVisible,
                    roomLabelsVisible: roomLabelsVisible,
                    roomAreasVisible: roomAreasVisible,
                    onAngleLockChanged: onAngleLockChanged,
                    onAngleStepChanged: onAngleStepChanged,
                    onContinuousDrawingChanged: onContinuousDrawingChanged,
                    onSmartGuidesChanged: onSmartGuidesChanged,
                    onCornerAnglesVisibleChanged: onCornerAnglesVisibleChanged,
                    onRoomLabelsVisibleChanged: onRoomLabelsVisibleChanged,
                    onRoomAreasVisibleChanged: onRoomAreasVisibleChanged,
                  ),
                      const SizedBox(width: 10),

                     if (onSave != null ||
                        onReload != null ||
                        onGeneratePlan != null ||
                        onExport != null ||
                        onOpen3d != null) ...[
                      _ToolbarProjectActions(
                        theme: theme,
                        isSaving: isSaving,
                        isDirty: isDirty,
                        saveStatusLabel: saveStatusLabel,
                        onSave: onSave,
                        onReload: onReload,
                        onGeneratePlan: onGeneratePlan,
                        onExport: onExport,
                        onOpen3d: onOpen3d,
                      ),
                      const SizedBox(width: 10),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBar(BuildContext context, dynamic theme, String zoomLabel) {
    final statusText = isSaving
        ? 'saving_status'.tr
        : isDirty
            ? 'unsaved_status'.tr
            : saveStatusLabel ?? 'saved_status'.tr;
    final statusColor = isSaving
        ? theme.themeColor
        : isDirty
            ? Colors.orange
            : Colors.green;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.dashboardContainer,
        border: Border(bottom: BorderSide(color: theme.dashboardBoarder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _ToolbarGroup(
            theme: theme,
            children: [
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.undo,
                tooltip: 'undo_tooltip'.tr,
                onPressed: canUndo ? onUndo : null,
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.redo,
                tooltip: 'redo_tooltip'.tr,
                onPressed: canRedo ? onRedo : null,
              ),
            ],
          ),
          const SizedBox(width: 8),
          _ToolbarGroup(
            theme: theme,
            children: [
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.zoom_out,
                tooltip: 'zoom_out_tooltip'.tr,
                onPressed: onZoomOut,
              ),
              _ToolbarValueChip(
                theme: theme,
                value: zoomLabel,
                tooltip: 'current_zoom_tooltip'.tr,
                minWidth: 48,
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.zoom_in,
                tooltip: 'zoom_in_tooltip'.tr,
                onPressed: onZoomIn,
              ),
              _ToolbarIconButton(
                theme: theme,
                icon: Icons.fit_screen_outlined,
                tooltip: 'reset_view_tooltip'.tr,
                onPressed: onResetView,
              ),
            ],
          ),
          const Spacer(),
          if (onSave != null) ...[
            _ToolbarIconButton(
              theme: theme,
              icon: Icons.save_outlined,
              tooltip: 'save_plan_tooltip'.tr,
              onPressed: isSaving ? null : () => onSave?.call(),
            ),
            const SizedBox(width: 4),
          ],
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(28),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withAlpha(90)),
            ),
            child: Center(
              child: Text(
                statusText,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarBrand extends StatelessWidget {
  final dynamic theme;

  const _ToolbarBrand({
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'floor_plan_brand_tooltip'.tr,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.themeColor.withAlpha(26),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.themeColor.withAlpha(70),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.architecture_outlined,
              color: theme.themeColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'plan_pro_brand'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarProjectActions extends StatelessWidget {
  final dynamic theme;
  final bool isSaving;
  final bool isDirty;
  final String? saveStatusLabel;
  final Future<void> Function()? onSave;
  final Future<void> Function()? onReload;
  final VoidCallback? onGeneratePlan;
  final Future<void> Function(FloorPlanExportFormat format)? onExport;
  final VoidCallback? onOpen3d;

  const _ToolbarProjectActions({
    required this.theme,
    required this.isSaving,
    required this.isDirty,
    required this.saveStatusLabel,
    required this.onSave,
    required this.onReload,
    required this.onGeneratePlan,
    required this.onExport,
    this.onOpen3d,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = isSaving
        ? 'saving_status'.tr
        : isDirty
            ? 'unsaved_status'.tr
            : saveStatusLabel ?? 'saved_status'.tr;

    final statusColor = isSaving
        ? theme.themeColor
        : isDirty
            ? Colors.orange
            : Colors.green;

    return _ToolbarGroup(
      theme: theme,
      label: 'project_label'.tr,
      children: [
        if (onGeneratePlan != null)
          _ToolbarTextActionButton(
            theme: theme,
            icon: Icons.auto_awesome,
            label: 'generate_button'.tr,
            tooltip: 'generate_plan_tooltip'.tr,
            onPressed: onGeneratePlan,
          ),
        if (onExport != null)
          _ToolbarExportMenu(
            theme: theme,
            onExport: onExport!,
          ),
        if (onReload != null)
          _ToolbarTextActionButton(
            theme: theme,
            icon: Icons.refresh,
            // label: 'Odśwież',
            tooltip: 'refresh_plan_tooltip'.tr,
            onPressed: isSaving
                ? null
                : () {
                    onReload?.call();
                  },
          ),
        if (onOpen3d != null)
          _ToolbarTextActionButton(
            theme: theme,
            icon: Icons.view_in_ar_outlined,
            label: 'Tryb 3D',
            tooltip: 'Otwórz ten plan w trybie 3D',
            onPressed: onOpen3d,
          ),
        if (onSave != null)
          _ToolbarTextActionButton(
            theme: theme,
            icon: Icons.save_outlined,
            // label: isSaving ? 'Zapis...' : 'Zapisz',
            tooltip: 'save_plan_tooltip'.tr,
            primary: true,
            isLoading: isSaving,
            onPressed: isSaving
                ? null
                : () {
                    onSave?.call();
                  },
          ),
        const SizedBox(width: 6),
        Tooltip(
          message: statusText,
          child: Container(
            height: 32,
            constraints: const BoxConstraints(minWidth: 88, maxWidth: 130),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(28),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: statusColor.withAlpha(90),
              ),
            ),
            child: Text(
              statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolbarExportMenu extends StatelessWidget {
  final dynamic theme;
  final Future<void> Function(FloorPlanExportFormat format) onExport;

  const _ToolbarExportMenu({
    required this.theme,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<FloorPlanExportFormat>(
      tooltip: 'export_plan_tooltip'.tr,
      color: theme.dashboardContainer,
      onSelected: onExport,
      itemBuilder: (context) {
        final formats = FloorPlanExportFormat.values
            .where((format) => format != FloorPlanExportFormat.webp)
            .toList();

        return formats.map((format) {
          return PopupMenuItem<FloorPlanExportFormat>(
            value: format,
            child: Row(
              children: [
                Icon(
                  _iconFor(format),
                  size: 18,
                  color: theme.textColor,
                ),
                const SizedBox(width: 10),
                Text(
                  format.label,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.ios_share_outlined,
              size: 18,
              color: theme.textColor,
            ),
            const SizedBox(width: 6),
            Text(
              'export_button'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: theme.textColor.withAlpha(150),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(FloorPlanExportFormat format) {
    switch (format) {
      case FloorPlanExportFormat.png:
        return Icons.image_outlined;
      case FloorPlanExportFormat.jpg:
        return Icons.photo_outlined;
      case FloorPlanExportFormat.webp:
        return Icons.image_search_outlined;
      case FloorPlanExportFormat.pdf:
        return Icons.picture_as_pdf_outlined;
    }
  }
}

class _ToolbarTextActionButton extends StatelessWidget {
  final dynamic theme;
  final IconData icon;
  final String? label;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool primary;
  final bool isLoading;

  const _ToolbarTextActionButton({
    required this.theme,
    required this.icon,
    this.label,
    required this.tooltip,
    required this.onPressed,
    this.primary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    final background = primary
        ? theme.themeColor.withAlpha(enabled ? 220 : 80)
        : Colors.transparent;

    final borderColor = primary
        ? theme.themeColor.withAlpha(enabled ? 230 : 90)
        : Colors.transparent;

    final color = enabled ? theme.textColor : theme.textColor.withAlpha(80);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                else
                  Icon(
                    icon,
                    size: 18,
                    color: color,
                  ),
                const SizedBox(width: 6),
                if(label != null)
                 Text(
                  label!,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarGroup extends StatelessWidget {
  final dynamic theme;
  final String? label;
  final List<Widget> children;

  const _ToolbarGroup({
    required this.theme,
    required this.children,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: theme.textColor.withAlpha(10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dashboardBoarder.withAlpha(180),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );

    if (label == null) return content;

    return Tooltip(
      message: label!,
      waitDuration: const Duration(milliseconds: 600),
      child: content,
    );
  }
}

class _ToolButton extends StatelessWidget {
  final dynamic theme;
  final bool selected;
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolButton({
    required this.theme,
    required this.selected,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showLabel = MediaQuery.of(context).size.width >= 600;
    final color = selected ? theme.textColor : theme.textColor.withAlpha(150);
    final background =
        selected ? theme.themeColor.withAlpha(210) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: showLabel ? 10 : 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? theme.themeColor.withAlpha(230)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final dynamic theme;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ToolbarIconButton({
    required this.theme,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
          color: enabled ? theme.textColor : theme.textColor.withAlpha(70),
        ),
      ),
    );
  }
}

class _ToolbarValueChip extends StatelessWidget {
  final dynamic theme;
  final String value;
  final String tooltip;
  final double minWidth;

  const _ToolbarValueChip({
    required this.theme,
    required this.value,
    required this.tooltip,
    this.minWidth = 58,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        height: 32,
        constraints: BoxConstraints(minWidth: minWidth),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: theme.dashboardBoarder,
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _AssetTypeSelector extends StatelessWidget {
  final dynamic theme;
  final FloorPlanAssetType selectedAssetType;
  final ValueChanged<FloorPlanAssetType> onChanged;

  const _AssetTypeSelector({
    required this.theme,
    required this.selectedAssetType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<FloorPlanAssetType>(
      tooltip: 'select_asset_type_tooltip'.tr,
      color: theme.dashboardContainer,
      onSelected: onChanged,
      itemBuilder: (context) {
        return FloorPlanAssetType.values.map((type) {
          return PopupMenuItem(
            value: type,
            child: Row(
              children: [
                Icon(
                  _assetIcon(type),
                  size: 18,
                  color: theme.textColor,
                ),
                const SizedBox(width: 10),
                Text(
                  type.label,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: type == selectedAssetType
                        ? FontWeight.w900
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.dashboardBoarder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _assetIcon(selectedAssetType),
              size: 18,
              color: theme.textColor,
            ),
            const SizedBox(width: 6),
            Text(
              selectedAssetType.label,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: theme.textColor.withAlpha(160),
            ),
          ],
        ),
      ),
    );
  }

  IconData _assetIcon(FloorPlanAssetType type) {
    switch (type) {
      case FloorPlanAssetType.sofa:
        return Icons.weekend_outlined;
      case FloorPlanAssetType.bed:
        return Icons.bed_outlined;
      case FloorPlanAssetType.table:
        return Icons.table_restaurant_outlined;
      case FloorPlanAssetType.chair:
        return Icons.chair_outlined;
      case FloorPlanAssetType.kitchen:
        return Icons.kitchen_outlined;
      case FloorPlanAssetType.wardrobe:
        return Icons.inventory_2_outlined;
      case FloorPlanAssetType.bathtub:
        return Icons.bathtub_outlined;
      case FloorPlanAssetType.shower:
        return Icons.shower_outlined;
      case FloorPlanAssetType.toilet:
        return Icons.wc_outlined;
      case FloorPlanAssetType.sink:
        return Icons.water_drop_outlined;
      case FloorPlanAssetType.car:
        return Icons.directions_car_outlined;
      case FloorPlanAssetType.stairs:
        return Icons.stairs_outlined;
      case FloorPlanAssetType.custom:
        return Icons.category_outlined;
    }
  }
}

class _ToolbarSettingsMenu extends StatelessWidget {
  final dynamic theme;

  final bool angleLockEnabled;
  final double angleStepDegrees;
  final bool continuousDrawingEnabled;
  final bool smartGuidesEnabled;
  final bool cornerAnglesVisible;
  final bool roomLabelsVisible;
  final bool roomAreasVisible;

  final ValueChanged<bool> onAngleLockChanged;
  final ValueChanged<double?> onAngleStepChanged;
  final ValueChanged<bool> onContinuousDrawingChanged;
  final ValueChanged<bool> onSmartGuidesChanged;
  final ValueChanged<bool> onCornerAnglesVisibleChanged;
  final ValueChanged<bool> onRoomLabelsVisibleChanged;
  final ValueChanged<bool> onRoomAreasVisibleChanged;

  const _ToolbarSettingsMenu({
    required this.theme,
    required this.angleLockEnabled,
    required this.angleStepDegrees,
    required this.continuousDrawingEnabled,
    required this.smartGuidesEnabled,
    required this.cornerAnglesVisible,
    required this.roomLabelsVisible,
    required this.roomAreasVisible,
    required this.onAngleLockChanged,
    required this.onAngleStepChanged,
    required this.onContinuousDrawingChanged,
    required this.onSmartGuidesChanged,
    required this.onCornerAnglesVisibleChanged,
    required this.onRoomLabelsVisibleChanged,
    required this.onRoomAreasVisibleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'drawing_view_settings_tooltip'.tr,
      color: theme.dashboardContainer,
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            enabled: false,
            child: _ToolbarMenuHeader(
              theme: theme,
              title: 'drawing_settings_title'.tr,
            ),
          ),
          PopupMenuItem<String>(
            enabled: false,
            child: _ToolbarMenuSwitch(
              theme: theme,
              value: angleLockEnabled,
              title: 'angle_snap_title'.tr,
              subtitle: 'alt_temporarily_disables_snap'.tr,
              onChanged: onAngleLockChanged,
            ),
          ),
          PopupMenuItem<String>(
            enabled: false,
            child: _AngleStepPicker(
              theme: theme,
              enabled: angleLockEnabled,
              value: angleStepDegrees,
              onChanged: onAngleStepChanged,
            ),
          ),
          PopupMenuItem<String>(
            enabled: false,
            child: _ToolbarMenuSwitch(
              theme: theme,
              value: continuousDrawingEnabled,
              title: 'continuous_drawing_title'.tr,
              subtitle: 'continuous_drawing_subtitle'.tr,
              onChanged: onContinuousDrawingChanged,
            ),
          ),
          PopupMenuItem<String>(
            enabled: false,
            child: _ToolbarMenuSwitch(
              theme: theme,
              value: smartGuidesEnabled,
              title: 'smart_guides_title'.tr,
              subtitle:
                  'smart_guides_subtitle'.tr,
              onChanged: onSmartGuidesChanged,
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            enabled: false,
            child: _ToolbarMenuHeader(
              theme: theme,
              title: 'layers_labels_title'.tr,
            ),
          ),
          PopupMenuItem<String>(
            enabled: false,
            child: _ToolbarMenuSwitch(
              theme: theme,
              value: cornerAnglesVisible,
              title: 'corner_angles_title'.tr,
              subtitle: 'corner_angles_subtitle'.tr,
              onChanged: onCornerAnglesVisibleChanged,
            ),
          ),
          PopupMenuItem<String>(
            enabled: false,
            child: _ToolbarMenuSwitch(
              theme: theme,
              value: roomLabelsVisible,
              title: 'room_labels_title'.tr,
              subtitle: 'room_labels_subtitle'.tr,
              onChanged: onRoomLabelsVisibleChanged,
            ),
          ),
          PopupMenuItem<String>(
            enabled: false,
            child: _ToolbarMenuSwitch(
              theme: theme,
              value: roomAreasVisible,
              title: 'room_areas_title'.tr,
              subtitle: 'room_areas_subtitle'.tr,
              onChanged: onRoomAreasVisibleChanged,
            ),
          ),
        ];
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.textColor.withAlpha(10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.dashboardBoarder.withAlpha(180),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.tune,
              color: theme.textColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'options_label'.tr,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: theme.textColor.withAlpha(150),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarMenuHeader extends StatelessWidget {
  final dynamic theme;
  final String title;

  const _ToolbarMenuHeader({
    required this.theme,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: theme.textColor,
        fontWeight: FontWeight.w900,
        fontSize: 13,
      ),
    );
  }
}

class _ToolbarMenuSwitch extends StatelessWidget {
  final dynamic theme;
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  const _ToolbarMenuSwitch({
    required this.theme,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      child: SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: theme.textColor.withAlpha(150),
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _AngleStepPicker extends StatelessWidget {
  final dynamic theme;
  final bool enabled;
  final double value;
  final ValueChanged<double?> onChanged;

  const _AngleStepPicker({
    required this.theme,
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final values = [15.0, 30.0, 45.0, 90.0];

    return SizedBox(
      width: 310,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'angle_step_label'.tr,
              style: TextStyle(
                color:
                    enabled ? theme.textColor : theme.textColor.withAlpha(90),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Wrap(
            spacing: 6,
            children: values.map((item) {
              final selected = item == value;

              return InkWell(
                onTap: enabled ? () => onChanged(item) : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.themeColor.withAlpha(180)
                        : theme.textColor.withAlpha(12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          selected ? theme.themeColor : theme.dashboardBoarder,
                    ),
                  ),
                  child: Text(
                    '${item.toStringAsFixed(0)}°',
                    style: TextStyle(
                      color: selected
                          ? theme.textColor
                          : theme.textColor.withAlpha(enabled ? 180 : 80),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Mobile Tool Sheet ─────────────────────────────────────────────────────────

class _MobileToolSheet extends ConsumerStatefulWidget {
  final FloorPlanTool selectedTool;
  final FloorPlanAssetType selectedAssetType;
  final bool isSaving;
  final bool isDirty;
  final String? saveStatusLabel;
  final Future<void> Function()? onSave;
  final Future<void> Function()? onReload;
  final VoidCallback? onGeneratePlan;
  final Future<void> Function(FloorPlanExportFormat format)? onExport;
  final VoidCallback? onOpen3d;
  final bool angleLockEnabled;
  final double angleStepDegrees;
  final bool continuousDrawingEnabled;
  final bool smartGuidesEnabled;
  final bool cornerAnglesVisible;
  final bool roomLabelsVisible;
  final bool roomAreasVisible;
  final ValueChanged<FloorPlanTool> onToolChanged;
  final ValueChanged<FloorPlanAssetType> onAssetTypeChanged;
  final ValueChanged<bool> onAngleLockChanged;
  final ValueChanged<double?> onAngleStepChanged;
  final ValueChanged<bool> onContinuousDrawingChanged;
  final ValueChanged<bool> onSmartGuidesChanged;
  final ValueChanged<bool> onCornerAnglesVisibleChanged;
  final ValueChanged<bool> onRoomLabelsVisibleChanged;
  final ValueChanged<bool> onRoomAreasVisibleChanged;

  const _MobileToolSheet({
    required this.selectedTool,
    required this.selectedAssetType,
    required this.isSaving,
    required this.isDirty,
    this.saveStatusLabel,
    this.onSave,
    this.onReload,
    this.onGeneratePlan,
    this.onExport,
    this.onOpen3d,
    required this.angleLockEnabled,
    required this.angleStepDegrees,
    required this.continuousDrawingEnabled,
    required this.smartGuidesEnabled,
    required this.cornerAnglesVisible,
    required this.roomLabelsVisible,
    required this.roomAreasVisible,
    required this.onToolChanged,
    required this.onAssetTypeChanged,
    required this.onAngleLockChanged,
    required this.onAngleStepChanged,
    required this.onContinuousDrawingChanged,
    required this.onSmartGuidesChanged,
    required this.onCornerAnglesVisibleChanged,
    required this.onRoomLabelsVisibleChanged,
    required this.onRoomAreasVisibleChanged,
  });

  @override
  ConsumerState<_MobileToolSheet> createState() => _MobileToolSheetState();
}

class _MobileToolSheetState extends ConsumerState<_MobileToolSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.14,
      minChildSize: 0.10,
      maxChildSize: 0.72,
      snap: true,
      snapSizes: const [0.14, 0.72],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: theme.dashboardBoarder)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.textColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // === Drawing tools ===
              _SheetSectionLabel(theme: theme, label: 'tools_label'.tr),
              _SheetToolRow(
                theme: theme,
                selectedTool: widget.selectedTool,
                onToolChanged: widget.onToolChanged,
                items: const [
                  _SheetToolItem(
                    tool: FloorPlanTool.select,
                    icon: Icons.near_me_outlined,
                    labelKey: 'select_tool_label',
                  ),
                  _SheetToolItem(
                    tool: FloorPlanTool.wall,
                    icon: Icons.show_chart,
                    labelKey: 'wall_tool_label',
                  ),
                  _SheetToolItem(
                    tool: FloorPlanTool.virtualWall,
                    icon: Icons.border_style,
                    labelKey: 'virtual_wall_tool_label',
                  ),
                  _SheetToolItem(
                    tool: FloorPlanTool.room,
                    icon: Icons.crop_square,
                    labelKey: 'room_tool_label',
                  ),
                  _SheetToolItem(
                    tool: FloorPlanTool.pan,
                    icon: Icons.pan_tool_alt_outlined,
                    labelKey: 'pan_tool_label',
                  ),
                ],
              ),
              // === Openings ===
              _SheetSectionLabel(theme: theme, label: 'openings_label'.tr),
              _SheetToolRow(
                theme: theme,
                selectedTool: widget.selectedTool,
                onToolChanged: widget.onToolChanged,
                items: const [
                  _SheetToolItem(
                    tool: FloorPlanTool.door,
                    icon: Icons.meeting_room_outlined,
                    labelKey: 'door_tool_label',
                  ),
                  _SheetToolItem(
                    tool: FloorPlanTool.window,
                    icon: Icons.window_outlined,
                    labelKey: 'window_tool_label',
                  ),
                  _SheetToolItem(
                    tool: FloorPlanTool.garageDoor,
                    icon: Icons.garage_outlined,
                    labelKey: 'garage_door_tool_label',
                  ),
                ],
              ),
              // === Assets ===
              _SheetSectionLabel(theme: theme, label: 'assets_label'.tr),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    _SheetToolTile(
                      theme: theme,
                      icon: Icons.weekend_outlined,
                      label: 'add_asset_tool_label'.tr,
                      selected: widget.selectedTool == FloorPlanTool.asset,
                      onTap: () => widget.onToolChanged(FloorPlanTool.asset),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AssetTypeSelector(
                        theme: theme,
                        selectedAssetType: widget.selectedAssetType,
                        onChanged: widget.onAssetTypeChanged,
                      ),
                    ),
                  ],
                ),
              ),
              // === Settings ===
              _SheetSectionLabel(theme: theme, label: 'options_label'.tr),
              _ToolbarMenuSwitch(
                theme: theme,
                value: widget.angleLockEnabled,
                title: 'angle_snap_title'.tr,
                subtitle: 'alt_temporarily_disables_snap'.tr,
                onChanged: widget.onAngleLockChanged,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _AngleStepPicker(
                  theme: theme,
                  enabled: widget.angleLockEnabled,
                  value: widget.angleStepDegrees,
                  onChanged: widget.onAngleStepChanged,
                ),
              ),
              _ToolbarMenuSwitch(
                theme: theme,
                value: widget.continuousDrawingEnabled,
                title: 'continuous_drawing_title'.tr,
                subtitle: 'continuous_drawing_subtitle'.tr,
                onChanged: widget.onContinuousDrawingChanged,
              ),
              _ToolbarMenuSwitch(
                theme: theme,
                value: widget.smartGuidesEnabled,
                title: 'smart_guides_title'.tr,
                subtitle: 'smart_guides_subtitle'.tr,
                onChanged: widget.onSmartGuidesChanged,
              ),
              // === Layers ===
              _SheetSectionLabel(theme: theme, label: 'layers_labels_title'.tr),
              _ToolbarMenuSwitch(
                theme: theme,
                value: widget.cornerAnglesVisible,
                title: 'corner_angles_title'.tr,
                subtitle: 'corner_angles_subtitle'.tr,
                onChanged: widget.onCornerAnglesVisibleChanged,
              ),
              _ToolbarMenuSwitch(
                theme: theme,
                value: widget.roomLabelsVisible,
                title: 'room_labels_title'.tr,
                subtitle: 'room_labels_subtitle'.tr,
                onChanged: widget.onRoomLabelsVisibleChanged,
              ),
              _ToolbarMenuSwitch(
                theme: theme,
                value: widget.roomAreasVisible,
                title: 'room_areas_title'.tr,
                subtitle: 'room_areas_subtitle'.tr,
                onChanged: widget.onRoomAreasVisibleChanged,
              ),
              // === Project actions ===
              if (widget.onGeneratePlan != null ||
                  widget.onExport != null ||
                  widget.onReload != null ||
                  widget.onOpen3d != null) ...[
                _SheetSectionLabel(
                    theme: theme, label: 'project_label'.tr),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.onGeneratePlan != null)
                        _ToolbarTextActionButton(
                          theme: theme,
                          icon: Icons.auto_awesome,
                          label: 'generate_button'.tr,
                          tooltip: 'generate_plan_tooltip'.tr,
                          onPressed: widget.onGeneratePlan,
                        ),
                      if (widget.onExport != null)
                        _ToolbarExportMenu(
                          theme: theme,
                          onExport: widget.onExport!,
                        ),
                      if (widget.onReload != null)
                        _ToolbarTextActionButton(
                          theme: theme,
                          icon: Icons.refresh,
                          tooltip: 'refresh_plan_tooltip'.tr,
                          onPressed: widget.isSaving
                              ? null
                              : () => widget.onReload?.call(),
                        ),
                      if (widget.onOpen3d != null)
                        _ToolbarTextActionButton(
                          theme: theme,
                          icon: Icons.view_in_ar_outlined,
                          label: 'Tryb 3D',
                          tooltip: 'Otwórz ten plan w trybie 3D',
                          onPressed: widget.onOpen3d,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  final dynamic theme;
  final String label;

  const _SheetSectionLabel({required this.theme, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: theme.textColor.withAlpha(110),
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _SheetToolItem {
  final FloorPlanTool tool;
  final IconData icon;
  final String labelKey;

  const _SheetToolItem({
    required this.tool,
    required this.icon,
    required this.labelKey,
  });
}

class _SheetToolRow extends StatelessWidget {
  final dynamic theme;
  final List<_SheetToolItem> items;
  final FloorPlanTool selectedTool;
  final ValueChanged<FloorPlanTool> onToolChanged;

  const _SheetToolRow({
    required this.theme,
    required this.items,
    required this.selectedTool,
    required this.onToolChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items
              .map(
                (item) => _SheetToolTile(
                  theme: theme,
                  icon: item.icon,
                  label: item.labelKey.tr,
                  selected: selectedTool == item.tool,
                  onTap: () => onToolChanged(item.tool),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SheetToolTile extends StatelessWidget {
  final dynamic theme;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetToolTile({
    required this.theme,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? theme.textColor : theme.textColor.withAlpha(150);
    final bg = selected
        ? theme.themeColor.withAlpha(210)
        : theme.textColor.withAlpha(10);
    final border = selected
        ? theme.themeColor.withAlpha(220)
        : theme.dashboardBoarder.withAlpha(130);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 72,
          height: 64,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight:
                      selected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}