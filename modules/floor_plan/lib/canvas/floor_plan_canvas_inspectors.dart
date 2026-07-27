part of 'floor_plan_canvas.dart';

class _MobileInspectorSheet extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const _MobileInspectorSheet({
    required this.child,
    required this.onDismiss,
  });

  @override
  ConsumerState<_MobileInspectorSheet> createState() =>
      _MobileInspectorSheetState();
}

class _MobileInspectorSheetState extends ConsumerState<_MobileInspectorSheet>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeColorsProvider);

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 0) {
          setState(() => _dragOffset += details.delta.dy);
        }
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset > 80 || (details.primaryVelocity ?? 0) > 400) {
          widget.onDismiss();
        } else {
          setState(() => _dragOffset = 0);
        }
      },
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Container(
          decoration: BoxDecoration(
            color: theme.dashboardContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: theme.dashboardBoarder),
              left: BorderSide(color: theme.dashboardBoarder),
              right: BorderSide(color: theme.dashboardBoarder),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WallInspector extends StatelessWidget {
  final FloorWall wall;
  final double pixelsPerMeter;
  final double currentAngleDeg;

  final ValueChanged<double> onLengthSubmitted;
  final ValueChanged<double> onThicknessSubmitted;
  final ValueChanged<double> onAngleSubmitted;
  final ValueChanged<bool> onAngleLockChanged;
  final ValueChanged<bool> onLengthLockChanged;
  final ValueChanged<double> onLockedLengthSubmitted;
  final ValueChanged<FloorWallKind> onWallKindChanged;

  final VoidCallback onAddDoorCenter;
  final VoidCallback onAddWindowCenter;
  final VoidCallback onDelete;
  final bool flat;

  const _WallInspector({
    required this.wall,
    required this.pixelsPerMeter,
    required this.currentAngleDeg,
    required this.onLengthSubmitted,
    required this.onThicknessSubmitted,
    required this.onAngleSubmitted,
    required this.onAngleLockChanged,
    required this.onLengthLockChanged,
    required this.onLockedLengthSubmitted,
    required this.onWallKindChanged,
    required this.onAddDoorCenter,
    required this.onAddWindowCenter,
    required this.onDelete,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final wallKind = wall.wallKind;

    final lengthM = wall.lengthM(pixelsPerMeter);
    final lockedAngle = wall.lockedAngleDeg ?? currentAngleDeg;
    final lockedLength = wall.lockedLengthM ?? lengthM;

    final isVirtualWall = wallKind == FloorWallKind.virtualWall;
    final title = wallKind.label;

    return _InspectorShell(
      width: 390,
      icon: wallKind.icon,
      title: title,
      onDelete: onDelete,
      flat: flat,
      children: [
        CoreDropdown<FloorWallKind>(
          label: 'wall_type_label'.tr,
          value: wallKind,
          options: FloorWallKind.values,
          display: (value) => value.label,
          onChanged: (value) {
            if (value == null) return;
            onWallKindChanged(value);
          },
        ),
        const SizedBox(height: 10),
        _InfoHintBox(
          icon: wallKind.icon,
          text: _wallKindDescription(wallKind),
        ),
        const SizedBox(height: 12),
        _InspectorTextField(
          fieldKey: ValueKey(
            'length_${wall.id}_${lengthM.toStringAsFixed(2)}',
          ),
          label: 'wall_length_label'.tr,
          initialValue: lengthM.toStringAsFixed(2),
          unit: 'm',
          helperText: 'enter_changes_wall_length'.tr,
          onSubmitted: (value) {
            final parsed = _parseDouble(value);
            if (parsed == null) return;
            onLengthSubmitted(parsed);
          },
        ),
        const SizedBox(height: 10),
        _InspectorTextField(
          fieldKey: ValueKey('thickness_${wall.id}_${wall.thickness}'),
          label: isVirtualWall
              ? 'helper_line_thickness_label'.tr
              : 'wall_thickness_label'.tr,
          initialValue: wall.thickness.toStringAsFixed(0),
          unit: 'cm',
          helperText: isVirtualWall
              ? 'virtual_wall_thickness_info'.tr
              : 'wall_thickness_example'.tr,
          onSubmitted: (value) {
            final parsed = _parseDouble(value);
            if (parsed == null) return;
            onThicknessSubmitted(parsed);
          },
        ),
        const SizedBox(height: 12),
        _InspectorSwitchTile(
          value: wall.angleLocked,
          onChanged: onAngleLockChanged,
          title: 'lock_wall_angle_label'.tr,
          subtitle: wall.angleLocked
              ? '${'angle_locked_format'.tr} ${lockedAngle.toStringAsFixed(1)}°'
              : 'wall_angle_not_locked_info'.tr,
        ),
        const SizedBox(height: 8),
        _InspectorTextField(
          fieldKey: ValueKey(
            'angle_${wall.id}_${lockedAngle.toStringAsFixed(1)}',
          ),
          label: 'wall_angle_label'.tr,
          initialValue: lockedAngle.toStringAsFixed(1),
          unit: '°',
          helperText: 'wall_angle_hint'.tr,
          onSubmitted: (value) {
            final parsed = _parseDouble(value);
            if (parsed == null) return;
            onAngleSubmitted(parsed);
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _AngleQuickButton(label: '0°', value: 0, onTap: onAngleSubmitted),
            _AngleQuickButton(label: '90°', value: 90, onTap: onAngleSubmitted),
            _AngleQuickButton(
              label: '180°',
              value: 180,
              onTap: onAngleSubmitted,
            ),
            _AngleQuickButton(
              label: '270°',
              value: 270,
              onTap: onAngleSubmitted,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InspectorSwitchTile(
          value: wall.lengthLocked,
          onChanged: onLengthLockChanged,
          title: 'lock_wall_length_label'.tr,
          subtitle: wall.lengthLocked
              ? '${'length_locked_format'.tr} ${lockedLength.toStringAsFixed(2)} m'
              : 'wall_length_not_locked_info'.tr,
        ),
        const SizedBox(height: 8),
        _InspectorTextField(
          fieldKey: ValueKey(
            'locked_length_${wall.id}_${lockedLength.toStringAsFixed(2)}',
          ),
          label: 'locked_length_label'.tr,
          initialValue: lockedLength.toStringAsFixed(2),
          unit: 'm',
          helperText: 'enter_sets_and_locks_length'.tr,
          onSubmitted: (value) {
            final parsed = _parseDouble(value);
            if (parsed == null) return;
            onLockedLengthSubmitted(parsed);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InspectorActionButton(
                onPressed: isVirtualWall ? null : onAddDoorCenter,
                icon: Icons.meeting_room_outlined,
                label: 'door_at_center_button'.tr,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _InspectorActionButton(
                onPressed: isVirtualWall ? null : onAddWindowCenter,
                icon: Icons.window_outlined,
                label: 'window_at_center_button'.tr,
              ),
            ),
          ],
        ),
        if (isVirtualWall) ...[
          const SizedBox(height: 8),
          _DisabledActionInfo(
            text:
                'virtual_wall_no_openings_info'.tr,
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _InfoChip(
                label: 'current_angle_label'.tr,
                value: '${currentAngleDeg.toStringAsFixed(1)}°',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoChip(
                label: 'length_label'.tr,
                value: '${lengthM.toStringAsFixed(2)} m',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _InfoChip(
                label: 'type_label'.tr,
                value: wallKind.label,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoChip(
                label: isVirtualWall ? 'line_label'.tr : 'thickness_label'.tr,
                value: isVirtualWall
                    ? 'virtual_label'.tr
                    : '${wall.thickness.toStringAsFixed(0)} cm',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _wallKindDescription(FloorWallKind kind) {
    switch (kind) {
      case FloorWallKind.partition:
        return 'partition_wall_description'.tr;
      case FloorWallKind.loadBearing:
        return 'load_bearing_wall_description'.tr;
      case FloorWallKind.virtualWall:
        return 'virtual_wall_description'.tr;
    }
  }
}

class _DoorInspector extends StatelessWidget {
  final Map<String, dynamic> door;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onDelete;
  final bool flat;

  const _DoorInspector({
    required this.door,
    required this.onChanged,
    required this.onDelete,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final widthM = (door['width_m'] as num?)?.toDouble() ?? 0.9;
    final position = (door['position'] as num?)?.toDouble() ?? 0.5;

    const allowedTypes = [
      'single',
      'double',
      'sliding',
      'garage_door',
    ];

    final rawType = door['type']?.toString() ?? 'single';
    final type = allowedTypes.contains(rawType) ? rawType : 'single';

    final swingRaw = door['swing_direction']?.toString() ?? 'left';
    final swingDirection =
        ['left', 'right'].contains(swingRaw) ? swingRaw : 'left';

    final isGarageDoor = type == 'garage_door';

    return _InspectorShell(
      width: 340,
      icon: isGarageDoor ? Icons.garage_outlined : Icons.meeting_room_outlined,
      title: isGarageDoor ? 'garage_door_title'.tr : 'door_title'.tr,
      onDelete: onDelete,
      flat: flat,
      children: [
        _InspectorTextField(
          fieldKey: ValueKey('door_width_${door['id']}_$widthM'),
          label: isGarageDoor ? 'garage_door_width_label'.tr : 'door_width_label'.tr,
          initialValue: widthM.toStringAsFixed(2),
          unit: 'm',
          onSubmitted: (value) {
            final parsed = _parseDouble(value);
            if (parsed == null) return;

            onChanged({
              ...door,
              'width_m': parsed.clamp(0.3, isGarageDoor ? 8.0 : 4.0),
            });
          },
        ),
        const SizedBox(height: 10),
        _InspectorTextField(
          fieldKey: ValueKey('door_position_${door['id']}_$position'),
          label: 'position_on_wall_label'.tr,
          initialValue: (position * 100).toStringAsFixed(0),
          unit: '%',
          helperText: 'position_on_wall_hint'.tr,
          onSubmitted: (value) {
            final parsed = _parseDouble(value);
            if (parsed == null) return;

            onChanged({
              ...door,
              'position': (parsed / 100).clamp(0.0, 1.0),
            });
          },
        ),
        const SizedBox(height: 10),
        CoreDropdown<String>(
          label: 'opening_type_label'.tr,
          value: type,
          options: allowedTypes,
          display: (value) {
            switch (value) {
              case 'single':
                return 'single_door_type'.tr;
              case 'double':
                return 'double_door_type'.tr;
              case 'sliding':
                return 'sliding_door_type'.tr;
              case 'garage_door':
                return 'garage_door_title'.tr;
              default:
                return value;
            }
          },
          onChanged: (value) {
            if (value == null) return;

            onChanged({
              ...door,
              'type': value,
            });
          },
        ),
        if (!isGarageDoor) ...[
          const SizedBox(height: 10),
          CoreDropdown<String>(
            label: 'swing_direction_label'.tr,
            value: swingDirection,
            options: const ['left', 'right'],
            display: (value) {
              switch (value) {
                case 'left':
                  return 'left_swing'.tr;
                case 'right':
                  return 'right_swing'.tr;
                default:
                  return value;
              }
            },
            onChanged: (value) {
              if (value == null) return;

              onChanged({
                ...door,
                'swing_direction': value,
              });
            },
          ),
        ],
        const SizedBox(height: 10),
        _InspectorActionButton(
          onPressed: () {
            onChanged({
              ...door,
              'position': 0.5,
            });
          },
          icon: Icons.center_focus_strong,
          label: 'center_on_wall_button'.tr,
        ),
      ],
    );
  }
}

class _WindowInspector extends StatelessWidget {
  final Map<String, dynamic> window;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onDelete;
  final bool flat;

  const _WindowInspector({
    required this.window,
    required this.onChanged,
    required this.onDelete,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final widthM = (window['width_m'] as num?)?.toDouble() ?? 1.2;
    final position = (window['position'] as num?)?.toDouble() ?? 0.5;
    final rawType = window['type']?.toString() ?? 'standard';
    final type = ['standard', 'balcony', 'corner', 'roof'].contains(rawType)
        ? rawType
        : 'standard';
    final sillHeightM = (window['sill_height_m'] as num?)?.toDouble() ?? 0.9;

    return _InspectorShell(
      width: 340,
      icon: Icons.window_outlined,
      title: 'window_title'.tr,
      onDelete: onDelete,
      flat: flat,
      children: [
        _InspectorTextField(
          fieldKey: ValueKey('window_width_${window['id']}_$widthM'),
          label: 'window_width_label'.tr,
          initialValue: widthM.toStringAsFixed(2),
          unit: 'm',
          onSubmitted: (value) {
            final parsed = _parseDouble(value);
            if (parsed == null) return;

            onChanged({
              ...window,
              'width_m': parsed.clamp(0.3, 8.0),
            });
          },
        ),
        const SizedBox(height: 10),
        _InspectorTextField(
          fieldKey: ValueKey('window_position_${window['id']}_$position'),
          label: 'position_on_wall_label'.tr,
          initialValue: (position * 100).toStringAsFixed(0),
          unit: '%',
          onSubmitted: (value) {
            final parsed = _parseDouble(value);
            if (parsed == null) return;

            onChanged({
              ...window,
              'position': (parsed / 100).clamp(0.0, 1.0),
            });
          },
        ),
        const SizedBox(height: 10),
        _InspectorTextField(
          fieldKey: ValueKey('window_sill_${window['id']}_$sillHeightM'),
          label: 'sill_height_label'.tr,
          initialValue: sillHeightM.toStringAsFixed(2),
          unit: 'm',
          onSubmitted: (value) {
            final parsed = _parseDouble(value);
            if (parsed == null) return;

            onChanged({
              ...window,
              'sill_height_m': parsed.clamp(0.0, 3.0),
            });
          },
        ),
        const SizedBox(height: 10),
        CoreDropdown<String>(
          label: 'window_type_label'.tr,
          value: type,
          options: const ['standard', 'balcony', 'corner', 'roof'],
          display: (value) {
            switch (value) {
              case 'standard':
                return 'standard_window_type'.tr;
              case 'balcony':
                return 'balcony_window_type'.tr;
              case 'corner':
                return 'corner_window_type'.tr;
              case 'roof':
                return 'roof_window_type'.tr;
              default:
                return value;
            }
          },
          onChanged: (value) {
            if (value == null) return;

            onChanged({
              ...window,
              'type': value,
            });
          },
        ),
        const SizedBox(height: 10),
        _InspectorActionButton(
          onPressed: () {
            onChanged({
              ...window,
              'position': 0.5,
            });
          },
          icon: Icons.center_focus_strong,
          label: 'center_on_wall_button'.tr,
        ),
      ],
    );
  }
}

class _RoomInspector extends StatelessWidget {
  final FloorRoom room;
  final double areaM2;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onDelete;
  final bool flat;

  const _RoomInspector({
    required this.room,
    required this.areaM2,
    required this.onNameChanged,
    required this.onDelete,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    return _InspectorShell(
      width: 320,
      icon: Icons.crop_square,
      title: 'room_title'.tr,
      onDelete: onDelete,
      flat: flat,
      children: [
        _InspectorTextField(
          fieldKey: ValueKey('room_name_${room.id}_${room.name}'),
          label: 'room_name_label'.tr,
          initialValue: room.name,
          keyboardType: TextInputType.text,
          onSubmitted: onNameChanged,
        ),
        const SizedBox(height: 10),
        _InfoChip(
          label: 'area_label'.tr,
          value: _formatAreaLabel(areaM2),
        ),
      ],
    );
  }
}

class _AssetInspector extends StatelessWidget {
  final FloorPlanAsset asset;
  final ValueChanged<FloorPlanAsset> onChanged;
  final VoidCallback onAlignToNearestWall;
  final VoidCallback onDelete;
  final bool flat;

  const _AssetInspector({
    required this.asset,
    required this.onChanged,
    required this.onAlignToNearestWall,
    required this.onDelete,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final type = floorPlanAssetTypeFromKey(asset.type);

    return _InspectorShell(
      width: 340,
      icon: Icons.weekend_outlined,
      title: type.label,
      onDelete: onDelete,
      flat: flat,
      children: [
        _InspectorActionButton(
          onPressed: onAlignToNearestWall,
          icon: Icons.align_horizontal_left_outlined,
          label: 'align_to_nearest_wall_button'.tr,
        ),
        const SizedBox(height: 10),
        _InspectorTextField(
          fieldKey: ValueKey('asset_label_${asset.id}_${asset.label}'),
          label: 'name_label'.tr,
          initialValue: asset.label ?? type.label,
          keyboardType: TextInputType.text,
          onSubmitted: (value) {
            onChanged(
              FloorPlanAsset(
                id: asset.id,
                type: asset.type,
                position: asset.position,
                widthM: asset.widthM,
                depthM: asset.depthM,
                rotationDeg: asset.rotationDeg,
                label: value.trim().isEmpty ? type.label : value.trim(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _InspectorTextField(
          fieldKey: ValueKey('asset_width_${asset.id}_${asset.widthM}'),
          label: 'width_label'.tr,
          initialValue: asset.widthM.toStringAsFixed(2),
          unit: 'm',
          onSubmitted: (value) {
            final parsed = _parseDouble(value);
            if (parsed == null || parsed <= 0) return;

            onChanged(
              FloorPlanAsset(
                id: asset.id,
                type: asset.type,
                position: asset.position,
                widthM: parsed,
                depthM: asset.depthM,
                rotationDeg: asset.rotationDeg,
                label: asset.label,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _InspectorTextField(
          fieldKey: ValueKey('asset_depth_${asset.id}_${asset.depthM}'),
          label: 'depth_label'.tr,
          initialValue: asset.depthM.toStringAsFixed(2),
          unit: 'm',
          onSubmitted: (value) {
            final parsed = _parseDouble(value);
            if (parsed == null || parsed <= 0) return;

            onChanged(
              FloorPlanAsset(
                id: asset.id,
                type: asset.type,
                position: asset.position,
                widthM: asset.widthM,
                depthM: parsed,
                rotationDeg: asset.rotationDeg,
                label: asset.label,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _InspectorTextField(
          fieldKey: ValueKey('asset_rotation_${asset.id}_${asset.rotationDeg}'),
          label: 'rotation_label'.tr,
          initialValue: asset.rotationDeg.toStringAsFixed(0),
          unit: '°',
          onSubmitted: (value) {
            final parsed = _parseDouble(value);
            if (parsed == null) return;

            onChanged(
              FloorPlanAsset(
                id: asset.id,
                type: asset.type,
                position: asset.position,
                widthM: asset.widthM,
                depthM: asset.depthM,
                rotationDeg: parsed,
                label: asset.label,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _InspectorShell extends ConsumerWidget {
  final double width;
  final IconData icon;
  final String title;
  final VoidCallback onDelete;
  final List<Widget> children;
  final bool flat;

  const _InspectorShell({
    required this.width,
    required this.icon,
    required this.title,
    required this.onDelete,
    required this.children,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    final maxHeight = math.min(
      MediaQuery.sizeOf(context).height * 0.75,
      760.0,
    );

    final inner = SingleChildScrollView(
          child: DefaultTextStyle(
            style: TextStyle(color: theme.textColor),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.themeColor.withAlpha(38),
                      foregroundColor: theme.textColor,
                      child: Icon(icon, color: theme.textColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline, color: theme.textColor),
                      tooltip: 'delete_button'.tr,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...children,
              ],
            ),
          ),
        );

    if (flat) return inner;

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(20),
      color: theme.dashboardContainer,
      child: Container(
        width: width,
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dashboardBoarder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: inner,
      ),
    );
  }
}

class _InspectorTextField extends StatefulWidget {
  final Key fieldKey;
  final String label;
  final String initialValue;
  final String? unit;
  final String? helperText;
  final TextInputType? keyboardType;
  final ValueChanged<String> onSubmitted;

  const _InspectorTextField({
    required this.fieldKey,
    required this.label,
    required this.initialValue,
    required this.onSubmitted,
    this.unit,
    this.helperText,
    this.keyboardType,
  });

  @override
  State<_InspectorTextField> createState() => _InspectorTextFieldState();
}

class _InspectorTextFieldState extends State<_InspectorTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode(debugLabel: 'FloorPlanInspectorField');
  }

  @override
  void didUpdateWidget(covariant _InspectorTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialValue == widget.initialValue) return;
    if (_focusNode.hasFocus) return;

    _controller.text = widget.initialValue;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: widget.fieldKey,
      child: CoreTextField(
        label: widget.label,
        controller: _controller,
        focusNode: _focusNode,
        keyboardType:
            widget.keyboardType ?? const TextInputType.numberWithOptions(
              decimal: true,
            ),
        textInputAction: TextInputAction.done,
        helperText: widget.helperText,
        suffixIcon: widget.unit == null ? null : _UnitSuffix(widget.unit!),
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}

class _UnitSuffix extends ConsumerWidget {
  final String value;

  const _UnitSuffix(this.value);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Center(
      widthFactor: 1,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Text(
          value,
          style: TextStyle(
            color: theme.textColor.withAlpha(170),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _InspectorSwitchTile extends ConsumerWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;

  const _InspectorSwitchTile({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      activeThumbColor: theme.themeColor,
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
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InspectorActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  const _InspectorActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return CoreOutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoHintBox extends ConsumerWidget {
  final IconData icon;
  final String text;

  const _InfoHintBox({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.themeColor.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.themeColor.withAlpha(45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: theme.textColor.withAlpha(180),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.textColor.withAlpha(170),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabledActionInfo extends ConsumerWidget {
  final String text;

  const _DisabledActionInfo({
    required this.text,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.orange.withAlpha(220),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.textColor.withAlpha(165),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLengthEditor extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;

  const _InlineLengthEditor({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return _InlineEditorShell(
      borderColor: theme.themeColor,
      width: 116,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: theme.textColor,
              ),
              cursorColor: theme.themeColor,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'm',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: theme.textColor,
            ),
          ),
          const SizedBox(width: 2),
          _InlineCloseButton(onTap: onCancel),
        ],
      ),
    );
  }
}

class _InlineAngleEditor extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;

  const _InlineAngleEditor({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return _InlineEditorShell(
      borderColor: theme.themeColor,
      width: 96,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: theme.textColor,
              ),
              cursorColor: theme.themeColor,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '°',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: theme.textColor,
            ),
          ),
          _InlineCloseButton(onTap: onCancel),
        ],
      ),
    );
  }
}

class _InlineRoomNameEditor extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;

  const _InlineRoomNameEditor({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return _InlineEditorShell(
      borderColor: theme.themeColor,
      width: 180,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: theme.textColor,
              ),
              cursorColor: theme.themeColor,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          _InlineCloseButton(onTap: onCancel),
        ],
      ),
    );
  }
}

class _InlineEditorShell extends ConsumerWidget {
  final double width;
  final Color borderColor;
  final Widget child;

  const _InlineEditorShell({
    required this.width,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      elevation: 14,
      borderRadius: BorderRadius.circular(14),
      color: theme.dashboardContainer,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _InlineCloseButton extends ConsumerWidget {
  final VoidCallback onTap;

  const _InlineCloseButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          Icons.close,
          size: 14,
          color: theme.textColor.withAlpha(150),
        ),
      ),
    );
  }
}

class _AngleQuickButton extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onTap;

  const _AngleQuickButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CoreOutlinedButton(
      onPressed: () => onTap(value),
      child: Text(label),
    );
  }
}

class _AngleBetweenWallsCard extends ConsumerWidget {
  final double angle;

  const _AngleBetweenWallsCard({
    required this.angle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: theme.dashboardContainer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.dashboardContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dashboardBoarder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.square_foot_outlined, size: 18, color: theme.textColor),
            const SizedBox(width: 8),
            Text(
              '${'angle_between_walls_prefix'.tr} ${angle.toStringAsFixed(1)}°',
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasHelpCard extends ConsumerWidget {
  final FloorPlanTool tool;

  const _CanvasHelpCard({
    required this.tool,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    String text;

    switch (tool) {
      case FloorPlanTool.select:
        text =
            'select_tool_help'.tr;
        break;
      case FloorPlanTool.wall:
        text =
            'wall_tool_help'.tr;
        break;
      case FloorPlanTool.virtualWall:
        text =
            'virtual_wall_tool_help'.tr;
        break;
      case FloorPlanTool.room:
        text =
            'room_tool_help'.tr;
        break;
      case FloorPlanTool.door:
        text = 'door_tool_help'.tr;
        break;
      case FloorPlanTool.window:
        text = 'window_tool_help'.tr;
        break;
      case FloorPlanTool.garageDoor:
        text = 'garage_door_tool_help'.tr;
        break;
      case FloorPlanTool.asset:
        text =
            'asset_tool_help'.tr;
        break;
      case FloorPlanTool.pan:
        text =
            'pan_tool_help'.tr;
        break;
    }

    return IgnorePointer(
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: theme.dashboardContainer.withAlpha(235),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dashboardBoarder),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.textColor.withAlpha(190),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends ConsumerWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.adPopBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dashboardBoarder),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.textColor.withAlpha(150),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}